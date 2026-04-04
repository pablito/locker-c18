#!/usr/bin/env bash
set -e

echo "🔧 Locker C18 — setup iniziale"

# 1. Installa devbox se non presente
if ! command -v devbox &>/dev/null; then
  echo "→ Installazione devbox..."
  # SECURITY: pipe-to-bash installs cannot be integrity-verified at runtime.
  # Before running this script, manually audit the installer URL or use the
  # official package manager installation documented at https://www.jetify.com/devbox/docs/installing_devbox/
  curl -fsSL https://get.jetify.com/devbox | bash
fi

# 2. Installa direnv se non presente
if ! command -v direnv &>/dev/null; then
  echo "→ Installazione direnv..."
  # SECURITY: same caveat as above. Alternative: install via your system package
  # manager (apt install direnv / brew install direnv / nix-env -i direnv).
  curl -sfL https://direnv.net/install.sh | bash
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
_DIRENV=$(command -v direnv 2>/dev/null \
  || echo "${HOME}/.local/bin/direnv" \
  || echo "/usr/local/bin/direnv")
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
