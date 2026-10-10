# Instruções para o Claude Code: instalar o claude-whatsapp-kit

Se o usuário te mandou o link deste repositório, ele quer que você instale tudo. Siga os passos na ordem, sem pedir confirmação a cada um, e fale com ele em português simples (não é programador).

## Passo a passo

1. **Clonar** (sempre em `~/projetos`, nunca em Documentos/Mesa por causa do iCloud):
   ```bash
   mkdir -p ~/projetos && cd ~/projetos
   [ -d claude-whatsapp-kit ] && git -C claude-whatsapp-kit pull || git clone https://github.com/vvgroupia-byte/claude-whatsapp-kit.git
   ```
   Se o `git` pedir para instalar as "ferramentas de linha de comando", baixe o zip em vez disso:
   `curl -L https://github.com/vvgroupia-byte/claude-whatsapp-kit/archive/refs/heads/main.zip -o /tmp/kit.zip && unzip -q /tmp/kit.zip -d /tmp && mv /tmp/claude-whatsapp-kit-main ~/projetos/claude-whatsapp-kit`

2. **Instalar** (rode com timeout de 10 minutos, baixa ~200 MB):
   ```bash
   ~/projetos/claude-whatsapp-kit/install.sh
   ```

3. **Conectar o WhatsApp.** Antes de rodar, avise o usuário: *"Vai abrir um QR code no navegador. Pegue o celular: WhatsApp > Configurações > Dispositivos conectados > Conectar dispositivo, e aponte para a tela."* Depois rode com timeout de 10 minutos:
   ```bash
   ~/projetos/claude-whatsapp-kit/connect.sh
   ```
   Se der tempo esgotado, pergunte se ele está pronto e rode de novo.

4. **Finalizar.** Diga ao usuário para fechar e abrir o Claude Code de novo (as ferramentas do WhatsApp só aparecem depois de reiniciar) e testar pedindo: *"lista minhas últimas conversas do WhatsApp"*.

## O que fica instalado

- Bridge do WhatsApp rodando em segundo plano (serviço `com.claude-whatsapp-kit.bridge`, liga sozinho com o Mac)
- MCP `whatsapp` no Claude Code: ler conversas, ver imagens, transcrever áudios, enviar mensagens
- Skill `whatsapp` em `~/.claude/skills/whatsapp/` com o modo de uso
- Whisper local para áudio (mlx-whisper no Mac M1+, whisper-ctranslate2 no Intel). O modelo (~1,6 GB) baixa em segundo plano na instalação

## Problemas

| Sintoma | O que fazer |
|---|---|
| `Porta 8080 já está em uso` | Ver quem usa: `lsof -nP -iTCP:8080 -sTCP:LISTEN`, pedir ao usuário para fechar e rodar o install de novo |
| QR não abre no navegador | Abrir à mão: `open ~/projetos/claude-whatsapp-kit/whatsapp-bridge/store/qr.html` |
| Erro no bridge | Ler `~/.local/share/claude-whatsapp-kit/bridge.log` |
| Primeira transcrição lenta | O modelo ainda está baixando; ver `~/.local/share/claude-whatsapp-kit/warmup.log` |
| Atualizar o kit | `cd ~/projetos/claude-whatsapp-kit && git pull && ./install.sh` |

Este kit é só para macOS. Em Windows/Linux, explique ao usuário que não é suportado.
