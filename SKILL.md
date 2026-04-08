---
name: locker
description: >-
  Configure a new project repository with a pre-built AI development environment.
  Shows an interactive template catalog and scaffolds the chosen environment into
  the current working directory — without overwriting existing files.
  Works with Claude Code, GitHub Copilot CLI, and OpenCode.
  Invoke when the user says /locker, "set up this repo", "initialize dev environment",
  "scaffold AI workspace", or any variant of bootstrapping a new project with AI agents.
---

# Locker

> *"You are the man who would be king of the train locker."*
> — Men in Black II (2002)

Bootstrap any repo with a fully-configured AI development environment — isolated, reproducible, multi-agent ready.

---

## How it works

When invoked, this skill:
1. Finds the template catalog from the skill installation
2. Presents available templates to the user
3. Copies the chosen template files into the **current working directory**
4. Never overwrites existing files — always warns and skips

---

## Step 1 — Locate the skill root

Run the following to find where this skill is installed:

```bash
# Try known installation paths (adjust if needed)
for candidate in \
  "${LOCKER_SKILL_ROOT}" \
  "${HOME}/.claude/skills/locker" \
  "${HOME}/.config/github-copilot/agents/skills/locker" \
  "${HOME}/.opencode/skills/locker" \
  "$(find "${HOME}" -maxdepth 6 -type f -name "SKILL.md" -path "*/locker/SKILL.md" 2>/dev/null | head -1 | xargs -r dirname)"
do
  if [[ -n "$candidate" && -f "${candidate}/templates/catalog.yaml" ]]; then
    SKILL_ROOT="$candidate"
    break
  fi
done

if [[ -z "$SKILL_ROOT" ]]; then
  echo "❌ Skill root not found. Set LOCKER_SKILL_ROOT to the skill installation path."
  exit 1
fi

echo "✅ Skill found at: $SKILL_ROOT"
```

## Step 2 — Read and present the catalog

Read `$SKILL_ROOT/templates/catalog.yaml` and present the available templates to the user in a clear numbered list:

```
Available templates:

  [1] a-01 — AI Dev Environment — Full Stack
      Ambiente isolato con Python 3.12, Node 20, .NET 8, MCP servers e sandbox Docker.
      Prerequisiti: devbox, direnv, docker

Select a template (enter the number or ID):
```

Wait for the user's selection before proceeding.

## Step 3 — Confirm before copying

Before copying any files, show the user:
- Which template was selected
- Which files will be created
- Which files already exist and will be **skipped**

Ask for confirmation: "Proceed? [y/N]"

## Step 4 — Copy template files

For each file in the selected template:

```bash
SRC="$SKILL_ROOT/templates/<template-id>/<file>"
DST="$(pwd)/<file>"

# Create parent directory if needed
mkdir -p "$(dirname "$DST")"

# Skip if file already exists — never overwrite
if [[ -f "$DST" ]]; then
  echo "⚠️  Skipping (already exists): $DST"
else
  cp -f "$SRC" "$DST"
  echo "✅ Created: $DST"
fi
```

## Step 5 — Post-setup summary

After copying, print a summary:

```
✅ Locker setup complete!

Files created:
  devbox.json
  .envrc
  .gitignore
  AGENTS.md
  mcp/config.json
  scripts/setup.sh
  ...

Files skipped (already existed):
  (none)

Next steps:
  1. Run: bash scripts/setup.sh
  2. Open a new terminal — devbox shell activates automatically
  3. Start your agent: claude / copilot / opencode
```

---

## Compatibility

| Agent | Invocation | Install command |
|-------|-----------|----------------|
| Claude Code | `/locker` | `claude skill install github:YOUR_ORG/locker-c18` |
| GitHub Copilot CLI | `/locker` | `copilot skill install github:YOUR_ORG/locker-c18` |
| OpenCode | `/locker` | `opencode skill install github:YOUR_ORG/locker-c18` |

---

## Adding new templates

To add a template to the catalog:
1. Create a folder under `templates/<id>/` with all scaffolding files
2. Add an entry to `templates/catalog.yaml` with the template metadata
3. Submit a PR to the locker repo

Template IDs follow the `x-yy` format (single letter category + two-digit number). The format is intentionally arbitrary — consistency over semantics.
