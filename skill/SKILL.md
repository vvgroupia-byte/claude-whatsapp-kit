---
name: whatsapp
description: Ler, resumir e responder conversas do WhatsApp, ver imagens e transcrever áudios recebidos. Use quando o usuário falar de WhatsApp, mensagens, conversas, contatos, áudios ou fotos recebidas.
---

# WhatsApp no Claude Code

O MCP `whatsapp` lê a base local do WhatsApp do usuário (sincronizada pelo bridge que roda em segundo plano).

## Como fazer cada coisa

| Pedido | Ferramentas |
|---|---|
| Ver conversas recentes | `list_chats` (ordenado por última mensagem) |
| Achar um contato ou grupo | `search_contacts` pelo nome; grupos aparecem em `list_chats` com `query` |
| Ler uma conversa | `list_messages` com `chat_jid` (e `limit`, `after`/`before` para datas) |
| Ver uma imagem, PDF ou vídeo | `download_media` (message_id + chat_jid) e depois abrir o `file_path` com a ferramenta Read |
| Ouvir um áudio | `transcribe_audio` (message_id + chat_jid), transcreve localmente com Whisper |
| Transcrever um arquivo do Mac | `transcribe_file` com o caminho absoluto |
| Enviar mensagem | `send_message`; arquivo com `send_file`; nota de voz com `send_audio_message` |

Mensagens com mídia aparecem em `list_messages` com o tipo (`[audio]`, `[image]`, `[document]`...). Ao resumir uma conversa, transcreva os áudios e abra as imagens relevantes para ter o contexto completo, em vez de ignorá-los.

## Regras

- **Nunca enviar nada sem o usuário aprovar o texto final e o destinatário.** Mostre o rascunho primeiro.
- Links de mídia antiga expiram: se `download_media` falhar numa mensagem de semanas atrás, avise em vez de insistir.
- Contatos podem aparecer como número `@lid`; procure pelo nome com `search_contacts`.

## Se não funcionar

| Sintoma | Solução |
|---|---|
| Ferramentas do whatsapp não aparecem | Reiniciar o Claude Code |
| Erro de conexão em localhost:8080 | Bridge parado: rodar `~/projetos/claude-whatsapp-kit/install.sh` |
| Conversas novas não chegam / pede QR | Sessão expirou: rodar `~/projetos/claude-whatsapp-kit/connect.sh` e escanear |
| Log do bridge | `~/.local/share/claude-whatsapp-kit/bridge.log` |
