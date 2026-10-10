# claude-whatsapp-kit

Liga o seu WhatsApp ao **Claude Code**: ele passa a ler as suas conversas, ver as fotos e documentos, **ouvir os áudios** (transcrição local e grátis) e, quando você aprovar, responder por você.

Só para **macOS** (Apple Silicon M1/M2/M3/M4 ou Intel). Não precisa de senha, Homebrew nem Xcode.

---

## Instalação (1 minuto do seu tempo)

Abra o Claude Code e cole esta mensagem:

```
Instala isto para mim: https://github.com/vvgroupia-byte/claude-whatsapp-kit
```

O Claude faz o resto. Quando ele pedir, pegue o celular, porque vai abrir um **QR code no navegador**:

> WhatsApp › Configurações › Dispositivos conectados › Conectar dispositivo › aponte para a tela

Depois feche e abra o Claude Code de novo. Pronto.

---

## O que pedir ao Claude

| Você diz | O que acontece |
|---|---|
| "Quais conversas do WhatsApp tenho por responder?" | Lista as conversas recentes |
| "Resume a conversa com a Maria desta semana" | Lê as mensagens, transcreve os áudios e abre as fotos para dar o contexto completo |
| "Transcreve o último áudio do João" | Baixa o áudio e transcreve no seu Mac |
| "O que tem na foto que o cliente mandou?" | Baixa a imagem e descreve |
| "Responde ao Pedro dizendo que amanhã às 10h está ok" | Mostra o rascunho e só envia depois de você aprovar |

---

## Instalação manual (se preferir fazer à mão)

```bash
mkdir -p ~/projetos && cd ~/projetos
git clone https://github.com/vvgroupia-byte/claude-whatsapp-kit.git
cd claude-whatsapp-kit
./install.sh
./connect.sh
```

## Manutenção

| Situação | Comando |
|---|---|
| O WhatsApp desconectou / pede QR de novo | `~/projetos/claude-whatsapp-kit/connect.sh` |
| Atualizar o kit | `cd ~/projetos/claude-whatsapp-kit && git pull && ./install.sh` |
| Ver o log | `cat ~/.local/share/claude-whatsapp-kit/bridge.log` |
| Desinstalar | `launchctl bootout gui/$(id -u)/com.claude-whatsapp-kit.bridge; rm ~/Library/LaunchAgents/com.claude-whatsapp-kit.bridge.plist; claude mcp remove whatsapp --scope user; rm -rf ~/projetos/claude-whatsapp-kit ~/.claude/skills/whatsapp` |

## Como funciona

```
Celular ──(Dispositivo conectado)──> bridge (Go, roda em 2º plano)
                                       │ grava mensagens em SQLite local
                                       ▼
                         MCP "whatsapp" (Python) ──> Claude Code
                                       │
                         Whisper local (áudio → texto)
```

- **Bridge**: [whatsmeow](https://github.com/tulir/whatsmeow), o mesmo protocolo do WhatsApp Web. Liga sozinho quando o Mac inicia.
- **MCP**: ferramentas `list_chats`, `list_messages`, `search_contacts`, `download_media`, `transcribe_audio`, `transcribe_file`, `send_message`, `send_file`, `send_audio_message`.
- **Áudio**: [mlx-whisper](https://github.com/ml-explore/mlx-examples/tree/main/whisper) (`whisper-large-v3-turbo`) no Apple Silicon, [whisper-ctranslate2](https://github.com/Softcatala/whisper-ctranslate2) no Intel. Tudo no seu Mac, nada vai para a nuvem.
- **Imagens**: o Claude já lê imagens nativamente; o kit só baixa o arquivo.

## Privacidade

As mensagens ficam **só no seu Mac**, em `whatsapp-bridge/store/` (fora do Git). O Claude só lê o que você pedir. Nunca compartilhe essa pasta.

## Créditos

Baseado em [lharries/whatsapp-mcp](https://github.com/lharries/whatsapp-mcp) (MIT), com: whatsmeow atualizado (o original é recusado pelo WhatsApp), correção do erro 403 ao baixar mídia, SQLite em Go puro (binário pronto, sem compilador), QR code no navegador, serviço automático, transcrição de áudio integrada e instalador de um comando.
