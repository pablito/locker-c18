#!/usr/bin/env bash
# Lancia un agente CLI in un container Docker isolato.
# Uso: devbox run sandbox -- claude
#      devbox run sandbox -- opencode
#      devbox run sandbox -- bash   (per debug)

set -e

: "${AGENT_SANDBOX_IMAGE:?AGENT_SANDBOX_IMAGE must be set (run inside devbox shell)}"

if ! docker info &>/dev/null; then
  echo "❌ Docker non disponibile. Assicurati che Docker Engine sia in esecuzione."
  exit 1
fi

# Build dell'immagine sandbox se non esiste
if ! docker image inspect "$AGENT_SANDBOX_IMAGE" &>/dev/null; then
  echo "→ Build immagine sandbox..."
  docker build -t "$AGENT_SANDBOX_IMAGE" ./sandbox/
fi

# Only forward the key the agent actually needs — never expose all credentials
# to a network-connected container. Add -e flags explicitly if other keys are required.
echo "🚀 Avvio sandbox: $*"
docker run --rm -it \
  --name "agent-$(date +%s)" \
  --user "$(id -u):$(id -g)" \
  -v "${PWD}:/workspace" \
  -w /workspace \
  -e ANTHROPIC_API_KEY \
  --network bridge \
  --memory 4g \
  --cpus 2 \
  "${AGENT_SANDBOX_IMAGE}" "$@"
