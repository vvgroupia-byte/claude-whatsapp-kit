#!/bin/bash
# Abre o QR code no navegador e espera o WhatsApp conectar (até 9 minutos).
# Use também quando a sessão expirar (o WhatsApp pede QR de novo de tempos em tempos).
set -uo pipefail

KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
STORE="$KIT_DIR/whatsapp-bridge/store"
LABEL="com.claude-whatsapp-kit.bridge"
LOG="$HOME/.local/share/claude-whatsapp-kit/bridge.log"

launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || { echo "Serviço não encontrado. Rode ./install.sh primeiro."; exit 1; }

# Reinicia o bridge e acompanha só o log novo
START=$(( $(wc -l < "$LOG" 2>/dev/null || echo 0) + 1 ))
rm -f "$STORE/qr.png" "$STORE/qr.html"
launchctl kickstart -k "gui/$(id -u)/$LABEL"
newlog() { tail -n "+$START" "$LOG" 2>/dev/null; }

OPENED=0
for _ in $(seq 1 270); do
  if [ -f "$STORE/qr.png" ] && [ "$OPENED" = 0 ]; then
    OPENED=1
    echo "QR code aberto no navegador."
    echo "No celular: WhatsApp > Configurações > Dispositivos conectados > Conectar dispositivo."
  fi
  if grep -q 'WhatsApp conectado' "$STORE/qr.html" 2>/dev/null; then
    echo "✓ WhatsApp conectado! As conversas estão sincronizando (pode levar alguns minutos)."
    echo "Reinicie o Claude Code e peça: \"lista minhas últimas conversas do WhatsApp\"."
    exit 0
  fi
  if [ "$OPENED" = 0 ] && newlog | grep -q 'Connected to WhatsApp'; then
    echo "✓ WhatsApp já está conectado. Nada a fazer."
    exit 0
  fi
  sleep 2
done
echo "Tempo esgotado. Rode ./connect.sh de novo quando estiver com o celular na mão."
exit 1
