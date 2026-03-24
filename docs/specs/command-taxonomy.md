# Command Taxonomy

**Status:** Draft — captured 2026-03-18, revised 2026-03-20 (rename-domain rewrite, no-git grace)
**Context:** Defines all domain-toolkit commands, their concerns, and relationships. Supersedes the command sections of `orchestrator-architecture.md` which predates the current design (sets, domain.yaml, file convention, Syncthing overlay).

---

## Design Principles

- **One command, one concern.** Each command does one thing well.
- **Commands compose.** The output of one can feed the input of another (e.g. touch-domain → add-domain).
- **Governance before action.** Commands respect the file convention load order: global governance → domain governance → persona → context.
- **Surface concerns, don't silently fix.** Unless explicitly asked (e.g. `-y` flag), commands report problems and let the human decide.

---

## Commands

### `touch-domain`

**Concern:** Kit health — structural validation, git precheck, profile regeneration, scaffolding, bootstrapping.

Operates from the outside, objectively. The universal entry point for domain maintenance.

**Modes:**

| Mode | Flag | What it does |
|------|------|-------------|
| Default (smart) | *(none)* | Inspect, validate structure, surface concerns |
| Full | `--full` | Everything default does + regenerate PROFILE.md |
| New | `--new` | Bootstrap a new domain from scratch |
| All | `--all` | Run `--full` across entire registry (warns first, always) |

**Modifiers:**

| Flag | Effect |
|------|--------|
| `--no-touchy` | Read-only diagnostic. No writes. Composes with any mode. |
| `-y` | Auto-confirm safe operations. Never overrides Diverged/Behind blocks. |

**Relationships:**
- Reads `domain.yaml` for git recovery context and validation
- Updates derived fields in `domain.yaml` (kit_health, last_touched)
- Writes/regenerates PROFILE.md, workspace file
- Surfaces git state per custodial checklist (see `set-assembly-spec.md`)
- Detects and surfaces AGENTS.md presence
- Checks domain.yaml `repo` field against directory basename
- Checks actual git remotes against domain.yaml `remotes`
- Can scaffold CLAUDE.md from global default if missing (self-propagation)

**Defined in:** `touch-domain` SKILL.md (existing, updated for domain.yaml and persona.md)

---

### `add-domain`

**Concern:** Registry management — scan, register, scaffold new domains.

**Modes:**

| Mode | Usage | What it does |
|------|-------|-------------|
| Add path | `add-domain <path>` | Read domain.yaml at path, add/update entry in registry |
| Update | `add-domain --update` | Walk all scan paths, re-scan domain.yaml files, rebuild registry |
| New | `add-domain --new <path>` | Scaffold a new domain (domain.yaml, .context/, CLAUDE.md) and register it |
| Scan path | `add-domain --scan-path <path>` | Add a path to the list of directories scanned by `--update` |

**Relationships:**
- Reads domain.yaml from each domain (the source of truth)
- Writes REGISTRY.yaml at `~/.claude/domain-toolkit/REGISTRY.yaml`
- Merge-not-replace: derived fields updated, user-declared fields preserved
- Builds sets reverse index from domain.yaml `sets` fields
- `add-domain --new` calls `touch-domain --new` under the hood, then registers
- Manages Syncthing folder setup as part of scaffolding

**Defined in:** `add-domain` SKILL.md. See `registry-spec.md` for specification.

---

### `open-domain`

**Concern:** Viewport launch — open a domain or set for interactive work.

**Usage:**

```
open-domain cashflow              # open a single domain
open-domain infrastructure        # open a set (if no domain matches the name)
open-domain cashflow --cursor     # open in Cursor/VS Code
open-domain cashflow --terminal   # open in terminal Claude Code
open-domain cashflow --container  # open as containerised viewport on fluffy
```

**Name resolution:** Domain name first, set name second (see `registry-spec.md`).

**For single domains:** Opens the domain viewport (workspace file, context tabs, Claude Code session).

**For sets:** Assembles worktrees in `~/.claude/domain-toolkit/worktrees/<set>/`, scaffolds set root governance (CLAUDE.md, AGENTS.md, .claude/domain-toolkit/domain.yaml), opens the set root in the specified viewport.

**For containerised viewports:** Orchestrates worktree assembly → container provisioning (DNS, reverse proxy, Docker) → returns URL.

**Relationships:**
- Reads registry for name resolution and domain/set lookup
- For sets: creates git worktrees, scaffolds set root
- For containers: orchestrates provisioning stack (bind9, nginx, Docker)
- Runs `touch-domain` on entry to surface concerns

**Defined in:** `open-domain` SKILL.md + `bin/open-domain` (existing, updated for domain.yaml/persona.md; sets and containers not yet implemented)

---

### `group-domain`

**Concern:** Set management — organise domains into named groups.

**Usage:**

```
group-domain infrastructure --add systems-harrklen
group-domain infrastructure --remove systems-harrklen
group-domain infrastructure       # list members
group-domain --list               # list all sets
```

**Relationships:**
- Modifies `sets` field in each affected domain's domain.yaml
- Triggers registry rebuild after changes
- Source of truth for set membership is always domain.yaml

**Defined in:** `group-domain` SKILL.md. See `registry-spec.md` for specification.

---

### `rename-domain`

**Concern:** Domain identity — rename a domain's logical name.

A domain has two names: the **domain name** (`name` field — logical identity, registry key) and the **repo name** (`repo` field — directory basename, bare repo name, remote URLs). These often match but don't have to. `rename-domain` changes only the domain name. Storage reorganisation (directory, bare repo, remotes) is a separate, deferred concern.

**Usage:**

```
rename-domain cashflow ledger              # rename the domain's logical name
rename-domain cashflow ledger --no-touchy  # dry run: show what would change
```

**Execution order:**
1. Update domain.yaml `name` field
2. Commit (if git repo; skip gracefully if not)
3. Rebuild registry via `add-domain --update`

After a name-only rename where `name != repo`, the domain is in a workable but untidy state. `touch-domain` surfaces the mismatch. The user resolves it when ready.

**Relationships:**
- Reads registry for name resolution and domain lookup
- Updates domain.yaml `name` field only
- Triggers registry rebuild via `add-domain --update`
- Does NOT touch repo field, directory, bare repo, remote URLs, prose references, or set names

**Defined in:** `rename-spec.md` (specification), `rename-domain` SKILL.md (implementation).

---

### `install-domain-toolkit`

**Concern:** Runtime lifecycle — deploy, validate, or remove the domain-toolkit runtime on a machine.

Sets up the machine-level infrastructure: hooks in `~/.claude/domain-toolkit/`, wrappers in `~/.claude/hooks/`, and registrations in `~/.claude/settings.json`. This is separate from domain-level management (touch-domain). Dual implementation: shell script (entrypoint for new users) + Claude Code skill.

**Modes:**

| Mode | Flag | What it does |
|------|------|-------------|
| Status | `--status` (default) | Transparent, detailed report of everything installed |
| Install | `--install` | Full copy deployment from repo |
| Link | `--link` | Symlink deployment (recommended for developers — git pull updates runtime) |
| Uninstall | `--uninstall` | Clean removal, preserving user data |

**Modifiers:**

| Flag | Effect |
|------|--------|
| `--cron` | Opt-in. Manage crontab entries from templates. Composable with install/link/uninstall. |

**Relationships:**
- Prerequisite for hooks, transcript staging, and cron automation
- Independent of touch-domain (machine setup vs domain health)
- Composes forward: after install → add-domain to register domains

**Defined in:** `install-spec.md` (specification), `install-domain-toolkit` SKILL.md + `bin/install-domain-toolkit` (implementation).

---

### `distill-domain`

**Concern:** Memory processing — post-session distillation.

Transforms session artifacts into canonical domain knowledge (MEMORY.md, DECISIONS.md updates). Runs in isolated context — objective, debiased by disk boundary.

**Usage:**

```
distill-domain <domain>           # distill a single domain
distill-domain --all              # walk registry, distill all domains with pending sessions
```

**Relationships:**
- Reads session artifacts from `.context/sessions/`
- Reads current MEMORY.md and DECISIONS.md
- Writes second-order re-synthesis directly (conflicts logged in DISTILL-CONFLICTS.md)
- Appends synthesis marker to CC session JSONL (high-water mark for incremental processing)
- Works with best available signal: agent-authored session notes as guaranteed minimum, richer sources (transcripts, gateway logs) when available

**Defined in:** `distill-domain` SKILL.md (existing, distiller prompt not yet written). See `distiller-spec.md` for specification.

---

### `overview` (sweep)

**Concern:** Capacity-aware briefing — scan registry, filter through personal domain profile, prioritise.

**What it does:**

1. Read the personal domain profile — operator's current state, capacity, constraints
2. Scan the registry — all subject domain profiles, `last_touched` currency, structural health
3. Produce a prioritised briefing — not "here are 30 things" but "given who you are right now, here's what deserves attention"

**Relationships:**
- Reads REGISTRY.yaml (all domain entries)
- Reads personal domain (Cursus) profile for capacity filtering
- Uses `last_touched` as primary currency signal
- May run `touch-domain --no-touchy` across domains for deeper health check
- This is a System 4 function (VSM) — intelligence, looking outward and forward

**Defined in:** `domain-overview` SKILL.md. See `domain-model-semantics.md` for the overview function design.

---

## Command Relationships

```
install-domain-toolkit → deploys runtime to ~/.claude/domain-toolkit/
                       → prerequisite for hooks, stager, cron

add-domain --new → touch-domain --new → add-domain (register)
                                      ↓
                                 open-domain (suggested)

add-domain --update → scans all domains → rebuilds REGISTRY.yaml

group-domain → modifies domain.yaml sets → triggers add-domain --update

rename-domain <old> <new> → updates domain.yaml name field
                           → commits (if git repo)
                           → triggers add-domain --update

open-domain <name> → resolves from registry
                   → single domain: opens viewport
                   → set: assembles worktrees, scaffolds set root, opens viewport

touch-domain → validates domain health
             → updates derived fields in domain.yaml
             → regenerates PROFILE.md (--full)
             → surfaces git concerns

overview → reads registry + personal domain → produces prioritised briefing

distill-domain → processes sessions → proposes MEMORY/DECISIONS updates
```

---

## Superseded

The following from `orchestrator-architecture.md` are superseded by this document and other session specs:

| Old concept | Replaced by |
|-------------|-------------|
| `/map` command | `add-domain` for registry management, `overview` for display/briefing |
| Registry as "format TBD, likely markdown" | `REGISTRY.yaml` (see `registry-spec.md`) |
| `agent.md` as detection signal | `domain.yaml` at `.claude/domain-toolkit/domain.yaml` (see `file-convention.md`) |
| Three commands (touch, open, distill) | Seven commands (touch, open, add, group, rename, distill, overview) |
| VS Code as only viewport | VS Code, terminal, containerised viewport (see `set-assembly-spec.md`, `storage-and-services.md`) |
| "The orchestrator runs as local user. No containers, no remote execution." | Containerised viewports on fluffy are a target (see `storage-and-services.md`) |
