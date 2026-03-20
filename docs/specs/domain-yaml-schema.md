# domain.yaml Schema

**Status:** Draft — captured from working session 2026-03-18
**Context:** Defines the schema for `.claude/domain-toolkit/domain.yaml`, the machine-readable manifest that serves as the detection signal for managed domains and the source of registry metadata.

---

## Location

`.claude/domain-toolkit/domain.yaml` — per-domain, tracked in git.

---

## Update Semantics

**Merge, not replace.** When `touch-domain` or `add-domain --update` refreshes a domain.yaml:

- **User-declared fields** are preserved. They are never overwritten by automation.
- **Derived fields** are overwritten from the filesystem scan.
- **Freeform keys** (any key not in the defined schema) are preserved.

If a user-declared field conflicts with something inferrable, the user-declared value wins.

---

## Schema

```yaml
# .claude/domain-toolkit/domain.yaml

# ── User-declared (preserved across updates) ──────────────────────

name: cashflow                   # Domain identity. How it appears in the registry,
                                 # what you pass to open-domain.

repo: cashflow                   # Declared repository name. If the directory basename
                                 # doesn't match, touch-domain surfaces this as a signal.

type: subject                    # subject | personal

description: >
  Personal finance — beancount ledgers, fava, import pipelines

sets:                            # Named groups. A domain can belong to multiple sets.
  - finance                      # Used by open-domain <name> to open a group.
  - geekazoid

# ── Git recovery context (user-declared, preserved) ───────────────

canonical_source: fluffy.geekazoid.net:/mnt/user/git/cashflow.git
                                 # The authoritative bare repo. "If everything goes wrong,
                                 # clone from here."

default_branch: main             # Expected tracking branch.

remotes:                         # Declared remote map. touch-domain checks actual git
  fluffy: fluffy.geekazoid.net:/mnt/user/git/cashflow.git
  github: git@github.com:geekaz01d/cashflow.git
                                 # remotes against this and flags discrepancies.
                                 # An agent repairing a checkout has everything it needs here.

# ── Derived (overwritten by touch-domain / add-domain --update) ───

kit_health: yes                  # yes | no | partial
                                 # Reflects structural health of .context/ at last check.

last_touched: 2026-03-18         # Date of last touch-domain run.

# ── Freeform (user-defined, always preserved) ─────────────────────
# Any additional keys are allowed and will be preserved across updates.
# Examples:
#   client: harrklen
#   priority: high
#   area: infrastructure
```

---

## Field Reference

### User-Declared

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Domain identity. Registry key. Argument to `open-domain`. |
| `repo` | string | Yes | Declared repository name. Discrepancy with directory basename is surfaced by `touch-domain`. |
| `type` | enum | Yes | `subject` or `personal`. Determines role in overview/sweep. |
| `description` | string | Yes | One-liner. What this domain is. |
| `sets` | list of strings | No | Named groups this domain belongs to. Used by `open-domain`. |
| `canonical_source` | string | No | Authoritative bare repo URL. Git recovery root. |
| `default_branch` | string | No | Expected tracking branch. Defaults to `main` if absent. |
| `remotes` | map (name → URL) | No | Declared git remotes. `touch-domain` verifies against actual git config. |

### Derived

| Field | Type | Description |
|-------|------|-------------|
| `kit_health` | enum | `yes`, `no`, or `partial`. Structural health of `.context/` at last check. |
| `last_touched` | date | Date of last `touch-domain` or `add-domain --update` run. |

### Installation Defaults (Meta-Domain Only)

These fields are specific to the domain-toolkit meta-domain's own `domain.yaml`. They provide installation-level defaults used by commands like `touch-domain --new` when bootstrapping new domains. Normal subject domains do not need these fields.

| Field | Type | Description |
|-------|------|-------------|
| `default_remote_pattern` | string | URL template for creating bare repos on new domains. Uses `{repo}` as the substitution variable (replaced with the `repo` field value). Example: `root@server:/mnt/git/{repo}.git` |

### Freeform

Any key not in the defined schema is allowed and preserved across updates. This supports domain-specific metadata without schema changes.

---

## Detection Signal

The presence of `.claude/domain-toolkit/domain.yaml` is the detection signal for a managed domain. This replaces the previous convention of checking for `.claude/agent.md`.

`touch-domain` and the SessionStart hook should check for this file to determine whether a directory participates in the domain-toolkit system.

---

## Validation Checks (`touch-domain`)

When `touch-domain` encounters a domain.yaml, it performs:

1. **Repo name match** — does the directory basename match the `repo` field? If not, flag it.
2. **Remote verification** — do the actual git remotes match the declared `remotes`? If not, flag discrepancies.
3. **Canonical source reachability** — is `canonical_source` reachable? If not, flag it.
4. **Branch check** — is `default_branch` the current branch? If not, note it.
5. **Schema completeness** — are all required user-declared fields present? If not, prompt.

These are surfaced as concerns, not silently fixed.
