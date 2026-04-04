#!/usr/bin/env bash
# .NET non è stabile in nixpkgs su tutti i target Linux/WSL2,
# quindi viene installato con lo script ufficiale Microsoft
# dentro la home del devbox shell — non tocca mai il sistema host.
#
# SECURITY: download the script, verify its SHA256, then execute.
# To refresh the checksum after Microsoft updates the script:
#   curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
#   sha256sum /tmp/dotnet-install.sh
# Then update DOTNET_INSTALL_SHA256 below.
DOTNET_INSTALL_SHA256="${DOTNET_INSTALL_SHA256:-}"

DOTNET_DIR="$HOME/.dotnet"

if ! command -v dotnet &>/dev/null; then
  echo "→ Installazione .NET 8..."
  curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh

  if [[ -n "$DOTNET_INSTALL_SHA256" ]]; then
    echo "${DOTNET_INSTALL_SHA256}  /tmp/dotnet-install.sh" | sha256sum -c - || {
      echo "❌ Checksum mismatch su dotnet-install.sh"
      rm -f /tmp/dotnet-install.sh
      exit 1
    }
  else
    echo "⚠️  DOTNET_INSTALL_SHA256 non impostata — esecuzione senza verifica integrità."
    echo "   Per abilitare la verifica: export DOTNET_INSTALL_SHA256=<hash>"
  fi

  bash /tmp/dotnet-install.sh \
    --channel 8.0 \
    --install-dir "$DOTNET_DIR" \
    --no-path
  rm -f /tmp/dotnet-install.sh
fi

export DOTNET_ROOT="$DOTNET_DIR"
export PATH="$PATH:$DOTNET_DIR"
