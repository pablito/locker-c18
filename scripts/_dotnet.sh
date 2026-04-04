#!/usr/bin/env bash
# .NET non è stabile in nixpkgs su tutti i target Linux/WSL2,
# quindi viene installato con lo script ufficiale Microsoft
# dentro la home del devbox shell — non tocca mai il sistema host.
#
# SECURITY: download the script, verify its SHA256, then execute.
# DOTNET_INSTALL_SHA256 MUST be set — unset = hard failure, not a warning.
# To refresh the checksum after Microsoft updates the script:
#   curl -sSL https://dot.net/v1/dotnet-install.sh | sha256sum
# Then export DOTNET_INSTALL_SHA256=<new-hash> (e.g. in devbox.json or .envrc).
: "${DOTNET_INSTALL_SHA256:?DOTNET_INSTALL_SHA256 must be set. Run: curl -sSL https://dot.net/v1/dotnet-install.sh | sha256sum}"

DOTNET_DIR="$HOME/.dotnet"

# Check for dotnet 8.x specifically — an older version on PATH must not block install
if ! (command -v dotnet &>/dev/null && dotnet --version 2>/dev/null | grep -q "^8\."); then
  echo "→ Installazione .NET 8..."
  _tmpfile=$(mktemp /tmp/dotnet-install.XXXXXX.sh)
  curl -sSL https://dot.net/v1/dotnet-install.sh -o "$_tmpfile"

  echo "${DOTNET_INSTALL_SHA256}  ${_tmpfile}" | sha256sum -c - || {
    echo "❌ Checksum mismatch su dotnet-install.sh — aggiorna DOTNET_INSTALL_SHA256"
    rm -f "$_tmpfile"
    exit 1
  }

  bash "$_tmpfile" \
    --channel 8.0 \
    --install-dir "$DOTNET_DIR" \
    --no-path
  rm -f "$_tmpfile"
fi

export DOTNET_ROOT="$DOTNET_DIR"
export PATH="$PATH:$DOTNET_DIR:$DOTNET_DIR/tools"
