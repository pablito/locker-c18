# Council Session — Template Catalog Spec Review

**Date:** 2026-04-05
**Council:** Full (Fowler, Beck, Uncle Bob, Evans, Linus)
**Subject:** Review of `docs/superpowers/specs/2026-04-05-template-catalog-design.md`
**Triggered by:** `/the-immortals` — architectural scope, cross-cutting

---

## 🏛️ The Immortals — Council Session

---

📐 **Fowler:**

I see three structural smells.

**Smell 1 — Inconsistent Override.** The merge strategy ("template files override scaffold files") is not a merge — it's a destructive copy. The pre-mortem correctly flags this for `AGENTS.md`, but the smell is broader: any scaffold customization is silently clobbered by any template file with the same name. The fix is a well-named **Strategy pattern**: define explicitly what "merge" means per file type. `AGENTS.md` → append. `.mcp.json` → deep merge. Everything else → template wins. This belongs in the spec as a table, not a footnote.

**Smell 2 — Shotgun Surgery.** `init.sh` touches beads, filesystem, git, JSON, and shell argument parsing. When any one of those changes — new beads flags, different stamp format, new file type — you edit the same script. That's five responsibilities in one procedure. In a compiled language I'd recommend decomposing it. In bash, at minimum the responsibilities should be named functions: `parse_args`, `copy_scaffold`, `init_beads`, `seed_memories`, `write_stamp`. Each testable in isolation.

**Smell 3 — GitHub Template / Generator conflation** (noted in pre-mortem). This is a **Divergent Change** smell: the repo serves two different masters — "template repo to fork" and "tool to run." These two identities will pull the structure in opposite directions. Keep them cleanly separated in the README with explicit sections for each use.

---

🔴 **Beck:**

What's the simplest thing that could possibly work?

I'm looking at `memories.txt`, `.locker` stamps, symlinked skills directories, append-merge strategies for AGENTS.md... and I want to ask: **has any of this been validated with an actual team lead?** This is a lot of mechanism for a problem we haven't proven exists at this scale.

The simplest version of "reproducible agent behavior across a team" is: a well-organized directory that you copy. One `cp -r templates/R-01-rails/ ~/my-project` and you're done. No script. No beads seeding. No stamp file. That delivers the core value — consistent conventions — with zero moving parts.

**Where's the test?** The bats suite exists. The spec has success criteria but no mention of bats tests for `init.sh`. Every step in the behavior list is a testable assertion: does `--list` print the right columns, does the stamp get written, does re-init get blocked. These must be in the spec before implementation begins.

My recommendation: spec v1 as the copy-only path first. Add beads seeding and stamp writing as wave 2, once the copy path has been validated with a real user.

---

🧹 **Uncle Bob:**

The naming bothers me.

`memories.txt` — memories of what? For whom? This file contains **project context for agents**. Call it `agent-context.txt`. The name should tell you what it is without reading its contents.

`.locker` — this is a provenance record, a lineage document. Why does it share the product name? Call it `.scaffold-provenance.json` or `.origin.json`. The name should say what it *does*, not where it came from.

`scaffold/` — "scaffold" is construction scaffolding, temporary by nature. But this base layer is permanent in the output. The name misleads. `base/` or `defaults/` is more honest.

On SRP: Fowler is right that `init.sh` has too many responsibilities, but I'd go further — the single biggest violation is that `init.sh` both *generates files* and *initializes external systems* (beads, git). File generation is pure and testable. External system initialization is impure and side-effectful. These must be clearly separated, even in bash. Name your functions. A function named `init_beads` can be mocked in tests. A 200-line script cannot.

---

🗺️ **Evans:**

What would the team lead actually call this thing?

She wouldn't say "I need to run the generator against the template catalog to scaffold a project." She'd say "I need to **set up** a new Rails project for my team." The language of the domain is: *set up*, *template*, *project type*, *team conventions*. The spec mostly honors this — `devbox run init R-01` reads naturally. Good.

But I want to name two domain concepts that are currently implicit:

**The Base Layer** is not just defaults — it's the **team's identity**: the conventions the team lead has established as universal. It should be named and treated as such. `scaffold/` undersells it. In the domain, this is "the team's baseline."

**The Template** is not just a collection of files — it's a **project archetype**: an opinionated starting point with known constraints (Rails uses RSpec; this archetype has a `web-api` shape). The invariant I'd protect: a project can only have one archetype at a time. The re-init guard isn't just a safety feature — it's enforcing this domain invariant.

The `.locker` stamp is a good idea, but its purpose is **provenance**, not locking. Rename it `.provenance` or `.origin` so the domain language is honest about what it records.

---

⚡ **Linus:**

Let me strip this to concrete operations.

The stamp file records `source` — a git remote URL — for the benefit of a bank that doesn't exist yet. That's metadata for a future system, carried in every scaffolded project from day one, read from a `git remote get-url origin` call that can fail. **Kill it.** In v1, the stamp needs exactly two fields: `template` and `scaffolded_at`. Everything else is speculation.

The skills deployment architecture (pre-mortem risk #2) is the most expensive risk here. You're looking at creating `.agents/skills/`, `.claude/skills/` symlinks, and `skills-lock.json` per template. That's three distinct filesystem operations plus the symlink creation logic. For each skill. In bash. With no package manager. This is going to be a fragile, hard-to-test piece of code. I'd strongly consider: don't ship per-template skills in v1. Ship a recommended skills list in `agent-context.txt` instead. Let the developer install skills manually with the existing skills tooling. One install step is far less brittle than a symlink factory.

Beck is right about the copy-first MVP. I'd go further: `init.sh` in v1 is four lines — `mkdir -p target-dir`, copy scaffold, copy template on top, write a two-field stamp. Everything else is wave 2.

---

⚖️ **Synthesis:**

The council agrees on three things:

1. **`init.sh` must be decomposed into named functions** — `copy_scaffold`, `init_beads`, `seed_memories`, `write_stamp` — even in bash. This is the minimum for testability and the bats test spec must cover each function.

2. **The merge strategy must be explicit, not implied.** Define it as a table in the spec: `AGENTS.md` appends, `.mcp.json` deep-merges, all other files template-wins. The current "template overrides scaffold" shorthand is insufficient.

3. **Naming needs a pass before implementation.** `memories.txt` → `agent-context.txt`. `scaffold/` → `base/`. The council is split on `.locker` (see Dissents).

---

🗳️ **Dissents:**

- **Beck** dissents on the full v1 scope: he'd ship wave 1 as copy-only (no beads init, no stamp, no memory seeding) and validate with a real user before building the rest. The others accept v1 as currently scoped but acknowledge this risk.
- **Linus** dissents on per-template skills in v1: too fragile, too many moving parts in bash, delivers marginal value over a manual install. Fowler, Evans, and Uncle Bob accept the skills architecture as necessary for the product vision but agree it should be the last thing built.
- **Linus** also dissents on the `source` field in the stamp: pure speculation tax. Evans and Fowler defend it as the minimum bank contract — without it, the bank has no provenance data. Beck sides with Linus: YAGNI.
