# locker-c18 Template Catalog — Design Spec

**Date:** 2026-04-05
**Status:** Draft

---

## Problem

locker-c18 currently provides a single devbox environment with AI agent CLIs pre-installed. This is not meaningfully different from a plain devbox configuration. The missing value is **reproducible agent behavior** — consistent conventions, skills, and AI boilerplate — distributed across a team's projects from a single authoritative source.

The target user is a **team lead** who wants every teammate working on a given project type to have the same agent conventions from day one, without manual configuration.

---

## Design

locker-c18 becomes a **template catalog**: a GitHub template repository that a team lead forks once, customizes for their team, and uses to scaffold new projects via a named template system.

### Repository structure

```
locker-c18/
├── scaffold/                    # base layer, applied to every project
│   ├── AGENTS.md                # shared agent conventions (memory, non-interactive shells)
│   ├── CLAUDE.md                # skeleton project instructions
│   └── .mcp.json.tpl            # MCP config template (filesystem, git, fetch)
├── templates/                   # named project templates
│   ├── catalog.json             # machine-readable template index
│   ├── R-01-rails/
│   │   ├── AGENTS.md            # Rails-specific agent conventions (overrides scaffold)
│   │   ├── CLAUDE.md            # Rails project instructions skeleton
│   │   ├── skills/              # skills active for this template
│   │   └── memories.txt         # bd remember calls to seed on init
│   ├── P-01-python-api/
│   │   └── ...
│   └── N-01-node-api/
│       └── ...
├── scripts/
│   ├── init.sh                  # generator: merges scaffold + template into target dir
│   └── ...                      # existing scripts unchanged
└── ...                          # existing repo files unchanged
```

### Template naming convention

Templates are named `<prefix>-<seq>-<slug>`:
- Prefix encodes the primary stack: `R` Ruby, `P` Python, `N` Node, `G` Go, `D` dotnet, etc.
- Sequence number (`01`, `02`) distinguishes variants within a stack (e.g., `R-01` Rails API, `R-02` Rails + Hotwire)
- Slug is human-readable: `rails`, `python-api`, `node-cli`

### catalog.json

A machine-readable index committed alongside the templates:

```json
{
  "version": "1",
  "templates": [
    {
      "id": "R-01",
      "name": "Ruby on Rails",
      "stack": "ruby",
      "archetype": "web-api",
      "description": "Rails 8 API with RSpec, beads issue tracking, standard agent conventions",
      "path": "templates/R-01-rails"
    }
  ]
}
```

This is the API surface a future locker bank would consume to query available templates and track which projects were scaffolded from which version.

### init.sh — the generator

```bash
devbox run init <template-id> [target-dir]
# Example:
devbox run init R-01 ~/projects/my-rails-app
devbox run init --list          # print catalog
```

Behavior:
1. Reads `catalog.json` to resolve the template path
2. Copies `scaffold/` into `target-dir` (base layer)
3. Merges `templates/<id>/` on top (template layer overrides scaffold)
4. Runs each line in `memories.txt` as `bd remember "<line>"` to seed agent memory
5. Writes a `.locker` stamp file recording template id, version, and date

Template files override scaffold files when both exist. The merge is a simple directory copy — no templating engine, no variable substitution in v1.

### .locker stamp file

Written to the root of the scaffolded project:

```json
{
  "template": "R-01",
  "source": "https://github.com/YOUR_ORG/locker-c18",
  "scaffolded_at": "2026-04-05",
  "locker_version": "1.0.0"
}
```

Enables future tooling (the bank) to audit which projects exist, which template they used, and whether they're behind the current template version.

### Pre-seeded beads memories

Each template ships a `memories.txt` — one fact per line, each run as `bd remember` during `init`:

```
# R-01-rails/memories.txt
This project uses RSpec for testing, not Minitest
Migrations are managed with Active Record — never write raw SQL schema changes
The Rails convention for service objects is app/services/<noun>_<verb>.rb
```

Agents arrive with project-type context already loaded. No blank slate.

---

## What locker-c18 is NOT

- Not a devbox replacement — it uses devbox as its runtime layer
- Not a package manager — it does not install language runtimes (devbox handles that)
- Not a sync tool — scaffolded projects are independent after init (bank propagation is future work)

---

## Locker bank (future, out of scope)

The bank is a decoupled thin wrapper: a GitHub org (or monorepo) where each repo was initialized from a named locker template. The `.locker` stamp and `catalog.json` are the data contract it depends on. Nothing in this design blocks adding the bank later.

---

## Out of scope for v1

- Variable substitution in template files
- Layered composition (stack × archetype × agent profile)
- Bank propagation (pushing convention updates to scaffolded projects)
- CLI packaging (`npx locker-c18 init`)
- Template versioning beyond the stamp file

---

## Success criteria

- A team lead can run `devbox run init R-01 ~/my-project` and get a fully configured project directory in under 30 seconds
- `devbox run init --list` prints the catalog
- The scaffolded project has beads initialized with template-specific memories pre-seeded
- The `.locker` stamp records provenance unambiguously
- Adding a new template requires only: a new directory under `templates/` and an entry in `catalog.json`
