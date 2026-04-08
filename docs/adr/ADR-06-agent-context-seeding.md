# ADR-06 — Agent Context Seeding via `agent-context.txt`

**Status**: Accepted  
**Date**: 2026-04-08  
**Deciders**: Paolo (owner), Marco (architecture review)  
**Supersedes**: —  
**Related**: Gap 5 in [Architecture Review](../../owner-inbox/locker-c18-architecture-review.md), design spec `docs/superpowers/specs/2026-04-05-template-catalog-design.md`

---

## Context

When a developer runs `/locker` and selects a template, the scaffolded repo starts with a blank agent memory store. Agents operating in that repo have no initial knowledge of project conventions, preferred test frameworks, naming rules, or domain vocabulary.

The design spec (reviewed by The Immortals council) proposed a `memories.txt` file (renamed `agent-context.txt` in council) as a per-template mechanism to pre-seed the Beads store with project-specific context at scaffold time.

Example: a Rails template would include entries such as:
- "This project uses RSpec, not Minitest."
- "Prefer `FactoryBot` over fixtures."
- "All controllers inherit from `ApplicationController`."

This is one of the differentiated value propositions of Locker: agents arrive already contextualised, not blank.

---

## Decision

Each template **may** include an `agent-context.txt` file at its root.

At scaffold time, if `agent-context.txt` is present in the selected template, the skill **seeds the Beads store** of the target repo by calling `bd remember` once per non-blank, non-comment line.

### File format

```
# Lines starting with '#' are comments — ignored at seeding time.
# Blank lines are also ignored.

This project uses RSpec, not Minitest.
Prefer FactoryBot over fixtures.
All controllers inherit from ApplicationController.
```

### Seeding behaviour

1. Skill detects `templates/<id>/agent-context.txt`
2. Skill reads the file, strips comments and blank lines
3. For each remaining line, executes: `bd remember "<line>"`
4. Emits a summary: "Seeded N memories from template agent-context."

### Scope

`agent-context.txt` belongs to the **template**, not to the skill repo itself. It is **not** deployed into the target repo — it is consumed at scaffold time and its content is written into the Beads store.

---

## Rationale

**Why `agent-context.txt` (not `memories.txt`)?**  
The council rename was motivated by clarity: "memories" implies an agent's internal state, while "context" describes what it is — project-specific information the agent needs. `agent-context.txt` is also self-documenting when a template author opens the directory.

**Why seed via `bd remember` rather than copying a file?**  
The Beads store is the canonical source of truth for agent memory. Writing directly to it (via the CLI) ensures that the seeded facts are retrievable via `bd prime`, searchable via `bd search`, and governed by the same TTL/compaction rules as hand-added memories. A flat file copy would create a shadow system outside Beads governance.

**Why not mandatory?**  
Templates that are purely structural (environment + toolchain, no domain knowledge) don't benefit from pre-seeded memories. Making the file optional avoids adding noise to simple templates.

**Why not `AGENTS.md`?**  
`AGENTS.md` is static documentation read at agent startup. It is appropriate for architectural rules and CLI references. `agent-context.txt`-seeded entries live in the Beads store, where they are dynamically retrieved and can be updated by agents over time. The two mechanisms are complementary.

---

## Consequences

### Positive
- Agents in scaffolded repos start with relevant project knowledge without requiring a bootstrapping session.
- Template authors can encode hard-won conventions once; every scaffold benefits.
- The seeding mechanism is transparent and auditable (each `bd remember` creates a traceable entry).

### Negative / risks
- Seeded memories can become stale if the template's `agent-context.txt` is updated but already-scaffolded repos are not re-seeded. Mitigation: document in template authoring guide that `agent-context.txt` changes do not auto-propagate.
- If `bd remember` fails silently (e.g., Beads not initialised in the target repo), seeding is a no-op. The skill must call `bd init` before seeding, or check for a `.beads/` directory.

### Open questions
- Should the skill initialise `bd init` in the target repo as part of the scaffold flow, or is this the developer's responsibility? (Tracked: locker-c18-TBD)
- Should `agent-context.txt` support categories/tags per line for finer retrieval? (Defer to v2.)

---

## Alternatives Considered

| Alternative | Reason Rejected |
|---|---|
| Copy `agent-context.txt` into target repo and let agent seed manually | Adds a manual step; defeats the purpose of automated onboarding |
| Embed memories directly in `AGENTS.md` | Conflates static instructions with dynamic memory; AGENTS.md grows unwieldy |
| `memories.txt` (original spec name) | Less expressive; renamed per council review |
| Defer entirely to v2 | The value is proportional to template richness; even a minimal template benefits from 3–5 seed entries |
