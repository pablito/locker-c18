# Agent Instructions

This environment is powered by **locker-c18** — an isolated, reproducible AI agent workspace.

## Memory

Beads (`bd`) is the **primary memory mechanism** in this environment. There is no MCP memory server.

```bash
bd remember "insight"       # Store a fact that should persist across sessions
bd memories <keyword>       # Retrieve stored knowledge by keyword
```

**Rules:**
- Use `bd remember` for any insight, decision, or context worth keeping across sessions
- Do NOT create MEMORY.md files — they fragment across agents and accounts
- Do NOT rely on in-session state for facts that need to survive a restart

## Issue Tracking

```bash
bd ready                    # Find available work
bd show <id>                # View issue details
bd update <id> --claim      # Claim work
bd close <id>               # Complete work
bd dolt push                # Sync beads to remote
```

Run `bd prime` for full workflow context and session close protocol.

## Non-Interactive Shell Commands

**ALWAYS use non-interactive flags** to avoid hanging on confirmation prompts.

```bash
cp -f source dest           # NOT: cp source dest
mv -f source dest           # NOT: mv source dest
rm -f file                  # NOT: rm file
rm -rf directory            # NOT: rm -r directory
apt-get install -y <pkg>    # NOT: apt-get install <pkg>
```

## Available Agents

```bash
claude          # Claude Code
opencode        # OpenCode
copilot         # GitHub Copilot CLI
```

To run an agent in an isolated container with maximum permissions and zero host impact:

```bash
devbox run sandbox -- claude
devbox run sandbox -- opencode
```
