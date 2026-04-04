#!/usr/bin/env bash
# .NET non è stabile in nixpkgs su tutti i target Linux/WSL2,
# quindi viene installato con lo script ufficiale Microsoft
# dentro la home del devbox shell — non tocca mai il sistema host.

DOTNET_DIR="$HOME/.dotnet"

if ! command -v dotnet &>/dev/null; then
  echo "→ Installazione .NET 8..."
  curl -sSL https://dot.net/v1/dotnet-install.sh | bash -s -- \
    --channel 8.0 \
    --install-dir "$DOTNET_DIR" \
    --no-path
fi

export DOTNET_ROOT="$DOTNET_DIR"
export PATH="$PATH:$DOTNET_DIR"
