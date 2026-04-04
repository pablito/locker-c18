#!/usr/bin/env bash
set -e

echo "🔧 Locker C18 — setup iniziale"

# 1. Installa devbox se non presente
if ! command -v devbox &>/dev/null; then
  echo "→ Installazione devbox..."
  curl -fsSL https://get.jetify.com/devbox | bash
fi

# 2. Installa direnv se non presente
if ! command -v direnv &>/dev/null; then
  echo "→ Installazione direnv..."
  curl -sfL https://direnv.net/install.sh | bash
fi

# 3. Hook direnv nella shell corrente
SHELL_NAME=$(basename "$SHELL")
RC_FILE="$HOME/.${SHELL_NAME}rc"
if ! grep -q 'direnv hook' "$RC_FILE" 2>/dev/null; then
  echo "→ Configurazione direnv in $RC_FILE..."
  echo 'eval "$(direnv hook '"$SHELL_NAME"')"' >> "$RC_FILE"
fi

# 4. Nota WSL2: assicurarsi di lavorare dentro il filesystem WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
  if [[ "$PWD" == /mnt/* ]]; then
    echo "⚠️  WSL2 rilevato: sposta il repo dentro il filesystem WSL (~/) per performance migliori"
    echo "   Esempio: cp -r . ~/locker-c18 && cd ~/locker-c18"
  fi
fi

echo ""
echo "✅ Setup completato."
echo "   Apri un nuovo terminale, torna in questa cartella e digita: devbox shell"
echo "   Oppure lascia che direnv lo attivi automaticamente."
