#!/bin/bash
# claude-whatsapp-kit: instala WhatsApp + transcrição de áudio no Claude Code (macOS).
# Não pede senha, não precisa de Homebrew nem Xcode. Pode rodar de novo quantas vezes quiser.
set -euo pipefail

REPO="vvgroupia-byte/claude-whatsapp-kit"
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRIDGE_DIR="$KIT_DIR/whatsapp-bridge"
SERVER_DIR="$KIT_DIR/whatsapp-mcp-server"
LOCAL_BIN="$HOME/.local/bin"
SHARE_DIR="$HOME/.local/share/claude-whatsapp-kit"
LABEL="com.claude-whatsapp-kit.bridge"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$SHARE_DIR/bridge.log"
ARCH="$(uname -m)"
export PATH="$LOCAL_BIN:$PATH"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
ok()   { printf '    \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '\n\033[31m✗ %s\033[0m\n' "$1"; exit 1; }

[ "$(uname -s)" = "Darwin" ] || fail "Este kit é para macOS."
case "$KIT_DIR" in
  "$HOME/Documents"*|"$HOME/Desktop"*|*"Mobile Documents"*)
    fail "Não instale dentro de Documentos/Mesa (o iCloud corrompe os arquivos). Clone em ~/projetos/claude-whatsapp-kit e rode de lá." ;;
esac
mkdir -p "$LOCAL_BIN" "$SHARE_DIR" "$BRIDGE_DIR/store" "$HOME/Library/LaunchAgents"

step "1/7 uv (gerenciador Python)"
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh >/dev/null \
    || fail "Não consegui baixar o uv. Verifique a internet (se o Claude Code estiver em sandbox, rode este script fora dele)."
fi
UV="$(command -v uv)"; ok "$UV"

step "2/7 ffmpeg (conversão de áudio)"
if ! command -v ffmpeg >/dev/null 2>&1; then
  "$UV" venv --quiet --python 3.12 --allow-existing "$SHARE_DIR/ffmpeg-venv"
  "$UV" pip install --quiet --python "$SHARE_DIR/ffmpeg-venv/bin/python" imageio-ffmpeg
  FF="$("$SHARE_DIR/ffmpeg-venv/bin/python" -c 'import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())')"
  ln -sf "$FF" "$LOCAL_BIN/ffmpeg"
fi
ok "$(command -v ffmpeg)"

step "3/7 Motor de transcrição (Whisper local, grátis)"
if [ "$ARCH" = "arm64" ]; then
  command -v mlx_whisper >/dev/null 2>&1 || "$UV" tool install --quiet --python 3.12 mlx-whisper
  ok "mlx-whisper (Apple Silicon)"
else
  command -v whisper-ctranslate2 >/dev/null 2>&1 || "$UV" tool install --quiet --python 3.12 whisper-ctranslate2
  ok "whisper-ctranslate2 (Mac Intel)"
fi

step "4/7 Bridge do WhatsApp"
BIN="$BRIDGE_DIR/whatsapp-bridge"
GOARCH_NAME=$([ "$ARCH" = "arm64" ] && echo arm64 || echo amd64)
if [ -f "$KIT_DIR/bin/whatsapp-bridge-darwin-$GOARCH_NAME" ]; then
  cp "$KIT_DIR/bin/whatsapp-bridge-darwin-$GOARCH_NAME" "$BIN"; chmod +x "$BIN"; ok "binário pronto"
elif curl -fsSL "https://github.com/$REPO/releases/latest/download/whatsapp-bridge-darwin-$GOARCH_NAME" -o "$BIN.new"; then
  mv "$BIN.new" "$BIN"; chmod +x "$BIN"; ok "binário pronto baixado"
else
  rm -f "$BIN.new"
  echo "    binário indisponível, compilando a partir do código..."
  GO="$HOME/.local/go/bin/go"
  if [ ! -x "$GO" ]; then
    GOV="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1)"
    curl -fsSL "https://go.dev/dl/$GOV.darwin-$GOARCH_NAME.tar.gz" | tar -xz -C "$HOME/.local"
  fi
  (cd "$BRIDGE_DIR" && CGO_ENABLED=0 "$GO" build -o "$BIN" .)
  ok "compilado"
fi

step "5/7 Servidor MCP (Python)"
(cd "$SERVER_DIR" && "$UV" sync --quiet)
ok "dependências instaladas"

step "6/7 Serviço automático (liga o bridge sempre que o Mac inicia)"
PORT_PID="$(lsof -nP -tiTCP:8080 -sTCP:LISTEN 2>/dev/null | head -1)"
if [ -n "$PORT_PID" ] && ! ps -p "$PORT_PID" -o comm= | grep -q whatsapp-bridge; then
  fail "A porta 8080 já está em uso por outro programa. Feche-o e rode o install.sh de novo."
fi
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$BIN</string></array>
  <key>WorkingDirectory</key><string>$BRIDGE_DIR</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>10</integer>
  <key>StandardOutPath</key><string>$LOG</string>
  <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
EOF
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
ok "bridge rodando em segundo plano"

step "7/7 Registro no Claude Code"
CLAUDE_BIN="$(command -v claude || true)"
if [ -n "$CLAUDE_BIN" ]; then
  "$CLAUDE_BIN" mcp remove whatsapp --scope user >/dev/null 2>&1 || true
  "$CLAUDE_BIN" mcp add whatsapp --scope user -- "$UV" --directory "$SERVER_DIR" run main.py >/dev/null
  ok "MCP 'whatsapp' registrado"
else
  echo "    'claude' não está no PATH. Rode isto manualmente:"
  echo "    claude mcp add whatsapp --scope user -- $UV --directory $SERVER_DIR run main.py"
fi
mkdir -p "$HOME/.claude/skills/whatsapp"
cp "$KIT_DIR/skill/SKILL.md" "$HOME/.claude/skills/whatsapp/SKILL.md"
ok "skill 'whatsapp' instalada"

# Baixa o modelo do Whisper (~1,6 GB) em segundo plano, para a 1ª transcrição ser rápida
( say -v Luciana "Teste de transcrição." -o "$SHARE_DIR/warmup.aiff" 2>/dev/null \
  && "$SERVER_DIR/.venv/bin/python" -c "import sys;sys.path.insert(0,'$SERVER_DIR');from transcribe import transcribe_file;print(transcribe_file('$SHARE_DIR/warmup.aiff'))" \
  > "$SHARE_DIR/warmup.log" 2>&1 ) &

printf '\n\033[1;32mInstalação concluída.\033[0m\n'
echo "Próximo passo: ./connect.sh  (abre o QR code no navegador e espera você escanear)"
