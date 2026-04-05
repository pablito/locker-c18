# locker-c18 Template Catalog — Design Spec

**Date:** 2026-04-05
**Status:** Draft — Pre-mortem annotations added 2026-04-05

---

## Problem

locker-c18 currently provides a single devbox environment with AI agent CLIs pre-installed. This is not meaningfully different from a plain devbox configuration. The missing value is **reproducible agent behavior** — consistent conventions, skills, and AI boilerplate — distributed across a team's projects from a single authoritative source.

The target user is a **team lead** who wants every teammate working on a given project type to have the same agent conventions from day one, without manual configuration.

---

## Design

locker-c18 becomes a **template catalog**: a GitHub template repository that a team lead forks once, customizes for their team, and uses to scaffold new projects via a named template system.

> ⚠️ **Pre-mortem risk — GitHub template conflation:** A GitHub template repo (the "Use this template" button) creates a full copy of the entire repo — including `templates/`, `scripts/`, `scaffold/`, and all generator machinery. That is the opposite of what the scaffolded project should contain. The GitHub template mechanism and `init.sh` generator are two different things and must not be conflated. Recommended resolution: locker-c18 is a GitHub template so team leads can fork it easily; `init.sh` is a separate tool that generates output into a *different* target directory. The README must make this distinction explicit.

### Repository structure

```
locker-c18/
├── scaffold/                    # base layer, applied to every project
│   ├── AGENTS.md                # shared agent conventions (memory, non-interactive shells)
│   ├── CLAUDE.md                # skeleton project instructions
│   └── .mcp.json                # static MCP config (filesystem, git, fetch)
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

> ⚠️ **Pre-mortem risk — Skills deployment architecture is incomplete:** Claude Code discovers skills via `.claude/skills/` symlinks pointing to `.agents/skills/`. Copying `templates/<id>/skills/` into `target-dir/skills/` creates a bare directory that agents cannot discover. The correct output structure requires: `.agents/skills/<skill-name>/` (skill content) + `.claude/skills/<skill-name>` (symlink) + `skills-lock.json` (provenance). `init.sh` must create this full structure, not just copy a flat `skills/` directory. The spec must be updated to reflect the real layout.

> ⚠️ **Pre-mortem risk — `.claude/settings.json` missing from scaffold:** The current locker-c18 `.claude/settings.json` has `bd prime` hooks on SessionStart and PreCompact. Scaffolded projects need these hooks too for agents to get beads context automatically. The scaffold layer should include a `.claude/settings.json` with the beads hooks pre-wired. Currently absent from the repository structure.

**Skills are template-only.** The `scaffold/` base layer does not include a `skills/` directory. Skills are curated per template and live exclusively under `templates/<id>/skills/`. This is intentional — there are no universal skills that apply to every project type.

### Template naming convention

Templates are named `<prefix>-<seq>-<slug>`:
- Prefix encodes the primary stack: `R` Ruby, `P` Python, `N` Node, `G` Go, `D` dotnet, etc.
- Sequence number (`01`, `02`) distinguishes variants within a stack (e.g., `R-01` Rails API, `R-02` Rails + Hotwire)
- Slug is human-readable: `rails`, `python-api`, `node-cli`

### catalog.json

A machine-readable index committed at the root of `templates/`:

```json
{
  "version": "1.0.0",
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

`archetype` describes the project shape — `web-api`, `cli`, `data-pipeline`, `library` — and is informational metadata for the bank and for `--list` output. It has no effect on init behavior in v1.

`version` in `catalog.json` is the **single source of truth for `locker_version`**. `init.sh` reads this field when writing the `.locker` stamp. It must be incremented manually when the catalog or scaffold changes in a way that affects scaffolded projects.

> ⚠️ **Pre-mortem risk — Manual version bump is invisible and un-enforced:** There is no tooling, git hook, or CI check that reminds the team lead to bump `catalog.json` version when templates change. In practice this will be forgotten. Every `.locker` stamp produced after a silent template change will carry the wrong version, silently corrupting the bank's audit capability. Recommended: add a `pre-commit` hook or `bd preflight` check that warns when `templates/` has changed but `catalog.json` version has not.

This is the API surface a future locker bank would consume to query available templates and track which projects were scaffolded from which version.

### init.sh — the generator

Exposed via `devbox.json` as a named script:

```json
"scripts": {
  "init": "bash scripts/init.sh"
}
```

Invoked as:

```bash
devbox run init <template-id> [target-dir]
# Examples:
devbox run init R-01 ~/projects/my-rails-app
devbox run init --list          # print catalog with id, name, archetype, description
```

`target-dir` defaults to the current directory if omitted.

> ⚠️ **Pre-mortem risk — `target-dir` may not exist:** The spec does not say whether `init.sh` creates `target-dir` if absent. `cp -r scaffold/ <non-existent-dir>` fails silently or with a confusing error. `init.sh` must `mkdir -p target-dir` before copying.

> ⚠️ **Pre-mortem risk — No guard against re-initialization:** Running `init` twice on the same `target-dir` silently overwrites scaffold files (losing any edits the team lead made), re-runs `bd init` (potentially resetting the beads store), and overwrites `.locker`. The script should detect `.locker` and exit with an error unless a `--force` flag is passed.

> ⚠️ **Pre-mortem risk — `devbox run init` must be invoked from inside the locker-c18 devbox shell:** This is a UX constraint not documented anywhere in the spec. A team lead who runs this from their regular shell will get a confusing failure. The README and `--help` output must make this explicit.

If `--list` is passed, argument parsing short-circuits before any file operations: reads `catalog.json` and prints one line per template in the format `<id>  <name>  <archetype>  <description>`, then exits. No other steps run.

Otherwise (`init <template-id> [target-dir]`):

1. Reads `catalog.json` to resolve the template path; exits with a non-zero error if `id` is not found
2. Resolves `target-dir`: defaults to the current directory if omitted
3. Copies `scaffold/` into `target-dir` (base layer)
4. Merges `templates/<id>/` on top — template files override scaffold files when both exist

> ⚠️ **Pre-mortem risk — Team lead customizations in `scaffold/AGENTS.md` are silently lost:** The whole point of forking locker-c18 is for the team lead to customize `scaffold/AGENTS.md` with team-wide conventions. If a template ships its own `AGENTS.md`, the plain `cp -r` merge overwrites the customized scaffold version. The team lead's work disappears without warning. Recommended: templates should not ship a top-level `AGENTS.md`; instead use a `AGENTS.append.md` that `init.sh` appends to the scaffold version rather than replacing it.

5. `cd`s into `target-dir`; runs `bd init` to initialize the beads store; all subsequent `bd` calls run from this directory

> ⚠️ **Pre-mortem risk — `bd init` generates its own AGENTS.md and installs git hooks:** By default, `bd init` creates an `AGENTS.md` in the working directory (overwriting the one just copied from scaffold/template) and installs git hooks (which fail if `target-dir` is not a git repo). `init.sh` must call `bd init --skip-agents --non-interactive` at minimum, and likely `--skip-hooks` if target-dir has no git repo yet. The exact flags must be specified.

6. If `memories.txt` exists in the template directory: reads it line by line, skips blank lines and lines beginning with `#`, runs `bd remember "<line>"` for each remaining line. If `memories.txt` is absent, this step is silently skipped — it is optional per template.
7. Reads the git remote URL (`git remote get-url origin`) from the locker-c18 repo (not from `target-dir`) to populate `source` in the stamp

> ⚠️ **Pre-mortem risk — `git remote get-url origin` is called after `cd target-dir`:** The script `cd`s into `target-dir` at step 5. Step 7 must read the remote from the locker-c18 directory, not target-dir. The implementation must capture the locker-c18 remote URL *before* the `cd`, or use an absolute path. As written the ordering implies a bug: the `cd` happens before the git remote read.

> ⚠️ **Pre-mortem risk — `git remote get-url origin` fails on local-only forks:** If the team lead cloned without a remote, renamed `origin`, or is running from a local checkout with no push URL configured, this command fails and the stamp gets a blank or error `source` field. `init.sh` should handle this gracefully: fall back to an empty string or warn, rather than aborting.

8. Writes `.locker` stamp file to `target-dir`; `scaffolded_at` is set to the output of `date -u +%F` (UTC, ISO 8601 format: `YYYY-MM-DD`)

The merge is a plain directory copy — no templating engine, no variable substitution in v1. `scaffold/.mcp.json` is copied as-is.

### .locker stamp file

Written to the root of the scaffolded project by `init.sh`:

```json
{
  "template": "R-01",
  "source": "https://github.com/your-org/locker-c18",
  "scaffolded_at": "2026-04-05",
  "locker_version": "1.0.0"
}
```

`source` is read from `git remote get-url origin` in the locker-c18 directory at init time — no placeholder, no manual editing required. `locker_version` is read from `catalog.json`. `scaffolded_at` is `date -u +%F` (UTC, `YYYY-MM-DD`).

Enables future tooling (the bank) to audit which projects exist, which template they used, and whether they are behind the current catalog version.

### Pre-seeded beads memories

Each template ships a `memories.txt` — one fact per line:

```
# Lines beginning with # are ignored by init.sh, as are blank lines.
This project uses RSpec for testing, not Minitest
Migrations are managed with Active Record — never write raw SQL schema changes
The Rails convention for service objects is app/services/<noun>_<verb>.rb
```

`init.sh` runs `bd init` before processing `memories.txt`, ensuring the beads store exists in the target project before any `bd remember` calls are made.

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
- Version diffing, upgrade paths, or enforcement across scaffolded projects (the stamp records version at scaffold time; detecting drift is a bank concern)

---

## Success criteria

- A team lead can run `devbox run init R-01 ~/my-project` and get a fully configured project directory in under 30 seconds
- `devbox run init --list` prints the catalog with id, name, archetype, and description
- After init, `bd memories` in the scaffolded project lists the entries from `memories.txt`
- The `.locker` stamp in the scaffolded project contains no placeholder values — `source` is the actual remote URL, `locker_version` matches `catalog.json`
- Adding a new template requires only: a new directory under `templates/`, an entry in `catalog.json`, and no changes to `init.sh`

---

## Pre-mortem risk summary

| # | Risk | Severity | Resolution |
|---|------|----------|------------|
| 1 | GitHub template conflation — generator ≠ template copy | High | Clarify in README; keep mechanisms distinct |
| 2 | Skills deployment architecture incomplete — bare `skills/` dir not discoverable | Critical | `init.sh` must create `.agents/skills/` + `.claude/skills/` symlinks + `skills-lock.json` |
| 3 | `.claude/settings.json` missing from scaffold — no beads hooks in generated projects | High | Add `.claude/settings.json` to `scaffold/` |
| 4 | `bd init` overwrites AGENTS.md and fails on non-git dirs | Critical | Use `bd init --skip-agents --non-interactive --skip-hooks` |
| 5 | Template AGENTS.md silently overwrites team lead's scaffold customizations | High | Templates use `AGENTS.append.md`; `init.sh` appends rather than overrides |
| 6 | `git remote get-url origin` called after `cd target-dir` — reads wrong directory | High | Capture remote URL before `cd` |
| 7 | `git remote get-url origin` fails on local-only repos | Medium | Graceful fallback to empty string with warning |
| 8 | No guard against re-initialization — silent overwrite | Medium | Detect `.locker` on entry; require `--force` to re-init |
| 9 | `target-dir` not created if absent | Medium | `mkdir -p target-dir` before copy |
| 10 | `devbox run init` must run inside locker-c18 devbox — undocumented | Medium | Document in README and `--help` |
| 11 | Catalog version bump is manual and un-enforced | Low | Pre-commit hook or `bd preflight` check |
