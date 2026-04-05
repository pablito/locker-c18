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

# 5. Installa beads (bd) — issue tracker con memoria persistente per agenti AI.
# Scarica il binario pre-compilato dalla release ufficiale e verifica il checksum.
# Non usiamo curl|bash: scarichiamo il binario, verifichiamo, poi installiamo.
BD_VERSION="1.0.0"
BD_INSTALL_DIR="${HOME}/.local/bin"
BD_BIN="${BD_INSTALL_DIR}/bd"

if ! command -v bd &>/dev/null && [[ ! -x "$BD_BIN" ]]; then
  echo "→ Installazione beads v${BD_VERSION}..."
  mkdir -p "$BD_INSTALL_DIR"

  _ARCH=$(uname -m)
  case "$_ARCH" in
    x86_64)  _BD_ARCH="amd64" ;;
    aarch64) _BD_ARCH="arm64" ;;
    *)
      echo "⚠️  Architettura non supportata per beads: $_ARCH — installa manualmente da https://github.com/gastownhall/beads/releases"
      _BD_ARCH=""
      ;;
  esac

  if [[ -n "$_BD_ARCH" ]]; then
    _BD_TARBALL="beads_${BD_VERSION}_linux_${_BD_ARCH}.tar.gz"
    _BD_URL="https://github.com/gastownhall/beads/releases/download/v${BD_VERSION}/${_BD_TARBALL}"
    _BD_CHECKSUMS_URL="https://github.com/gastownhall/beads/releases/download/v${BD_VERSION}/checksums.txt"
    _BD_TMP=$(mktemp -d)

    curl -fsSL -o "${_BD_TMP}/${_BD_TARBALL}" "$_BD_URL"
    curl -fsSL -o "${_BD_TMP}/checksums.txt" "$_BD_CHECKSUMS_URL"

    # Verifica checksum prima di installare
    cd "$_BD_TMP"
    if ! grep "$_BD_TARBALL" checksums.txt | sha256sum -c --status; then
      echo "❌ Checksum beads non valido — installazione annullata."
      rm -rf "$_BD_TMP"
      exit 1
    fi

    tar -xzf "$_BD_TARBALL" -C "$_BD_TMP"
    mv "${_BD_TMP}/bd" "$BD_BIN"
    chmod +x "$BD_BIN"
    rm -rf "$_BD_TMP"
    cd - >/dev/null
    echo "✓ beads v${BD_VERSION} installato in ${BD_BIN}"
  fi
fi

# Aggiungi ~/.local/bin al PATH se non presente (necessario per bd).
if [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
  SHELL_NAME_TMP=$(basename "$SHELL")
  RC_FILE_TMP="$HOME/.${SHELL_NAME_TMP}rc"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC_FILE_TMP"
  export PATH="${HOME}/.local/bin:${PATH}"
fi

# 7. Nota WSL2: assicurarsi di lavorare dentro il filesystem WSL
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
