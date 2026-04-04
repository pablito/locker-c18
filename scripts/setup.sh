#!/usr/bin/env bash
set -e

echo "🔧 Locker C18 — setup iniziale"

# 1. Controlla devbox — non auto-installare via curl|bash (non verificabile).
# Installa manualmente seguendo le istruzioni ufficiali:
#   https://www.jetify.com/devbox/docs/installing_devbox/
if ! command -v devbox &>/dev/null; then
  echo "❌ devbox non trovato."
  echo "   Installalo manualmente: https://www.jetify.com/devbox/docs/installing_devbox/"
  exit 1
fi

# 2. Installa direnv tramite package manager (verificato da apt/brew/nix GPG).
if ! command -v direnv &>/dev/null; then
  echo "→ Installazione direnv..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get install -y direnv
  elif command -v brew &>/dev/null; then
    brew install direnv
  elif command -v nix-env &>/dev/null; then
    nix-env -i direnv
  else
    echo "❌ Nessun package manager supportato trovato (apt/brew/nix)."
    echo "   Installa direnv manualmente: https://direnv.net/docs/installation.html"
    exit 1
  fi
fi

# 3. Hook direnv nella shell dell'utente.
# $SHELL reflects the user's configured login/interactive shell — the right
# target for the hook even when this script is run with a different interpreter.
SHELL_NAME=$(basename "$SHELL")
RC_FILE="$HOME/.${SHELL_NAME}rc"
if ! grep -q 'direnv hook' "$RC_FILE" 2>/dev/null; then
  echo "→ Configurazione direnv in $RC_FILE..."
  echo 'eval "$(direnv hook '"$SHELL_NAME"')"' >> "$RC_FILE"
fi

# 4. Autorizza direnv per questa directory in modo che si attivi automaticamente.
# Try PATH-visible binary first, then common installer fallback locations.
# Use || true: if this fails (e.g. fresh install, PATH not yet updated), the
# user can run 'direnv allow .' themselves after reopening their terminal.
for _DIRENV in "$(command -v direnv 2>/dev/null)" "${HOME}/.local/bin/direnv" "/usr/local/bin/direnv"; do
  [[ -x "$_DIRENV" ]] && break
done
if [[ -x "$_DIRENV" ]]; then
  "$_DIRENV" allow . || true
fi

# 5. Nota WSL2: assicurarsi di lavorare dentro il filesystem WSL
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
