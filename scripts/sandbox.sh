#!/usr/bin/env bash
# Lancia un agente CLI in un container Docker isolato.
# Uso: devbox run sandbox -- claude
#      devbox run sandbox -- opencode
#      devbox run sandbox -- bash   (per debug)

set -e

if ! docker info &>/dev/null; then
  echo "❌ Docker non disponibile. Assicurati che Docker Engine sia in esecuzione."
  exit 1
fi

# Build dell'immagine sandbox se non esiste
if ! docker image inspect "$AGENT_SANDBOX_IMAGE" &>/dev/null; then
  echo "→ Build immagine sandbox..."
  docker build -t "$AGENT_SANDBOX_IMAGE" ./sandbox/
fi

echo "🚀 Avvio sandbox: $*"
docker run --rm -it \
  --name "agent-$(date +%s)" \
  --user "$(id -u):$(id -g)" \
  -v "${PWD}:/workspace" \
  -w /workspace \
  -e ANTHROPIC_API_KEY \
  -e GITHUB_TOKEN \
  -e OPENAI_API_KEY \
  --network bridge \
  --memory 4g \
  --cpus 2 \
  "${AGENT_SANDBOX_IMAGE}" "$@"
