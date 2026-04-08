# ADR-07 — Provenance Stamp (`.locker` file)

**Status**: Accepted  
**Date**: 2026-04-08  
**Deciders**: Paolo (owner), Marco (architecture review)  
**Supersedes**: —  
**Related**: Gap 6 in architecture review, design spec `docs/superpowers/specs/2026-04-05-template-catalog-design.md`

---

## Context

When the skill scaffolds a repo, it leaves no record of what was applied. This creates several problems:

1. **Re-init guard**: there is no reliable marker to detect that a repo was already initialised by Locker (see also the re-init guard issue).
2. **Debugging**: a developer encountering a scaffolded repo has no quick way to know which template was used.
3. **Future locker bank**: if Locker evolves into a "locker bank" with update/upgrade semantics (drift detection, template version upgrades), knowing the origin template and version is a prerequisite.

The design spec proposed a `.locker` file written into the target repo. The council debated its contents:
- **Linus position**: minimum viable — template id + date only. Keep it simple; provenance files accumulate noise.
- **Evans position**: include `source` (the skill repo URL) to enable the locker bank scenario.

---

## Decision

The skill writes a `.locker` file at the root of the target repo after a successful scaffold.

### File format

```yaml
# Written by locker-c18 at scaffold time. Do not edit manually.
template: c-18
scaffolded_at: 2026-04-08T14:32:00Z
locker_source: github:pablito/locker-c18
```

### Fields

| Field | Required | Description |
|---|---|---|
| `template` | Yes | Template ID as defined in `templates/*/meta.yaml` |
| `scaffolded_at` | Yes | ISO 8601 UTC timestamp of scaffold operation |
| `locker_source` | Yes | Skill source identifier (as used in `claude skill install`) |

### Placement

`.locker` is placed at the root of the target repo (same level as `devbox.json`). It is **not** added to `.gitignore` — it should be committed and visible in the repo history.

---

## Rationale

**Why include `locker_source` (Evans position over Linus minimum)?**  
The `source` field costs nothing to write and enables the locker bank scenario without requiring a file format migration later. The Linus minimum (template + date) is a strict subset. Adding `source` now preserves optionality; removing it later from deployed repos is not feasible.

**Why YAML and not JSON?**  
The file is human-readable by design — a developer opening the repo should understand it at a glance. YAML with inline comments (the `# Written by...` header) is self-documenting. JSON would require a schema reference to explain fields.

**Why `.locker` (dotfile) and not `locker.yaml` or `.locker.yaml`?**  
Dotfiles at repo root signal tooling configuration (`.gitignore`, `.envrc`, `.editorconfig`). A dotfile is less likely to be confused with project source. The `.locker` name is consistent with the product name.

**Why is `.locker` not in `.gitignore`?**  
Provenance is version-controlled intent, not a build artifact or secret. Committing `.locker` means `git log` shows when the scaffold happened. This is desirable.

**Re-init guard usage**  
The presence of `.locker` at repo root is the **canonical marker** for the re-init guard: if `/locker` is invoked on a repo where `.locker` already exists, the skill should warn and require explicit `--force` confirmation before proceeding. See related issue for full guard logic.

---

## Consequences

### Positive
- Deterministic re-init detection: `.locker` is the single authoritative marker.
- Audit trail in `git log`: scaffold events are visible in repo history.
- Locker bank / drift detection enabled in future versions without format migration.
- Simple debugging: `cat .locker` answers "what was applied here?".

### Negative / risks
- Developers may delete `.locker` accidentally, disabling the re-init guard. Mitigation: the guard is a safety net, not a lock; if the file is gone, behaviour degrades to a first-time install (acceptable).
- If the template is renamed or the skill repo changes URL, `locker_source` may point to a stale location. Mitigation: treat `locker_source` as an informational hint, not a live reference.

---

## Alternatives Considered

| Alternative | Reason Rejected |
|---|---|
| `.locker.yaml` | Less consistent with dotfile conventions |
| `locker.json` | JSON is less human-readable for this use case |
| Detect re-init via `devbox.json` presence | `devbox.json` may exist for non-Locker reasons; false positives |
| No provenance file (defer to v2) | Re-init guard has no clean implementation without a marker; cost is trivial |
| Embed provenance in `AGENTS.md` as a comment | `AGENTS.md` is editable agent documentation; embedding metadata there couples two concerns |
