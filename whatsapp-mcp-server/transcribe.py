import os
import platform
import shutil
import subprocess
import tempfile

LOCAL_BIN = os.path.expanduser("~/.local/bin")
MLX_MODEL = "mlx-community/whisper-large-v3-turbo"
CT2_MODEL = "large-v3-turbo"


def _env():
    """Environment with ~/.local/bin on PATH so ffmpeg and whisper CLIs are found."""
    env = os.environ.copy()
    env["PATH"] = LOCAL_BIN + os.pathsep + env.get("PATH", "")
    return env


def _find(name):
    return shutil.which(name, path=_env()["PATH"])


def _engine():
    """mlx-whisper on Apple Silicon, whisper-ctranslate2 (faster-whisper) on Intel Macs."""
    if platform.machine() == "arm64" and _find("mlx_whisper"):
        return "mlx", _find("mlx_whisper")
    if _find("whisper-ctranslate2"):
        return "ct2", _find("whisper-ctranslate2")
    raise RuntimeError("Nenhum motor de transcrição encontrado. Rode o install.sh do claude-whatsapp-kit.")


def transcribe_file(path, language="pt"):
    """Transcribe an audio file locally and return the text.

    Args:
        path: audio file (ogg/opus from WhatsApp, mp3, m4a, wav...)
        language: ISO code ("pt", "en", "es"...) or "auto" to detect
    """
    if not os.path.isfile(path):
        raise FileNotFoundError(f"Arquivo não encontrado: {path}")
    ffmpeg = _find("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("ffmpeg não encontrado. Rode o install.sh do claude-whatsapp-kit.")

    engine, binary = _engine()
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "audio.wav")
        subprocess.run([ffmpeg, "-y", "-i", path, "-ar", "16000", "-ac", "1", wav],
                       check=True, capture_output=True, env=_env())

        if engine == "mlx":
            cmd = [binary, wav, "--model", MLX_MODEL, "--output-format", "txt", "--output-dir", tmp]
        else:
            cmd = [binary, wav, "--model", CT2_MODEL, "--compute_type", "int8",
                   "--output_format", "txt", "--output_dir", tmp]
        if language and language != "auto":
            cmd += ["--language", language]

        result = subprocess.run(cmd, capture_output=True, text=True, env=_env())
        txt = os.path.join(tmp, "audio.txt")
        if result.returncode != 0 or not os.path.isfile(txt):
            raise RuntimeError(f"Falha na transcrição: {result.stderr[-800:]}")
        with open(txt, encoding="utf-8") as f:
            return f.read().strip()
