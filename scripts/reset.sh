#!/usr/bin/env bash
set -e

echo "🔄 Reset ambiente..."
rm -rf .venv
rm -f .mcp.json
devbox shell -- bash scripts/_mcp.sh
uv sync --quiet
echo "✅ Ambiente resettato."
