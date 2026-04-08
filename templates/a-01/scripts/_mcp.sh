#!/usr/bin/env bash
# Genera .mcp.json nella root del progetto.
# Questo file viene letto sia da Claude Code che da OpenCode.
# Copilot CLI usa un meccanismo diverso (estensioni),
# ma il file non interferisce.

# Rigenera solo se non esiste ancora
if [[ -f .mcp.json ]]; then
  return 0 2>/dev/null || exit 0
fi

cat > .mcp.json <<EOF
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."]
    },
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git", "--repository", "."]
    },
    "fetch": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch"]
    }
  }
}
EOF

echo "→ .mcp.json generato con filesystem, git, fetch"
echo "   Memoria persistente: usa 'bd remember' / 'bd memories' (beads)"
