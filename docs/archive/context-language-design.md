# Context Management Language — Design

_Status: design complete, nothing built yet_

---

## Vision

A minimal command language for managing Claude session contexts across projects, clients, and machines. CLI-first, token-efficient, composable. No MCP servers. SSH + bash is the data pipeline.

---

## The Language

### Verbs

| Verb | Behavior |
|---|---|
| `start` | Launch a new isolated session with named context(s) |
| `switch` | Restart current session with new context, same tab |
| `include` | Add a named context to current scope |
| `exclude` | Remove a named context from current scope |
| `close` | Save state and close current context cleanly |
| `forget` | Drop context without saving |
| `preview` | Dry-run: show what a command would do, cost estimate, confirm gate |

### Operators

- `and` — compose multiple Names: `start security and systems-geekazoid`
- `all` — expand to all Names in registry: `security and all`
- `all <scope>` — scoped expansion: `all contexts`, `all skills`, `all acme-corp`

### Syntax

```
<verb> <name> [and <name> ...] [as <alias>] [--flag]
```

### `as` operator

Names a composition, making it canonical:

```
start systems-geekazoid and systems-architectures as geekazoid-full
```

`as` does three things atomically:
1. Names the Guake tab
2. Creates `~/.claude/cursor_workspaces/geekazoid-full.code-workspace`
3. Registers `geekazoid-full` as a composed Name — `start geekazoid-full` works from then on

Without `as`, a composition is ephemeral: workspace file goes to `.ephemeral/`, no registry entry, cleaned up on close.

**Skills are excluded from workspace filenames.** `start security and systems-geekazoid` produces `systems-geekazoid.code-workspace` — security is a session posture, not a folder.

---

## Names

Names are the nouns. A Name resolves to one of:

| Type | Resolves to |
|---|---|
| Context | A directory containing `CLAUDE.md` |
| Skill | A posture/behavior modifier file |
| Composed | A context + one or more skills |

Names are **uniform** — the verb language does not distinguish type. Resolution handles it.

### Registry format (`~/.claude/names`)

```
systems-geekazoid=/workspaces/geekazoid/sources/systems-geekazoid  context
systems-architectures=/workspaces/geekazoid/sources/systems-architectures  context
fluffy=/workspaces/geekazoid/sources/systems-geekazoid/docs/FLUFFY.geekazoid.net  context
security=~/.claude/skills/security.md  skill
zero-trust=~/.claude/skills/zero-trust.md  skill
token-saver=~/.claude/skills/token-saver.md  skill
home=~/.claude/home  context
```

### Scanner

Lean script (`scan-contexts.sh`) — idempotent, run on demand or on change:

1. Read scan roots from `~/.claude/scanner-roots`
2. Find all `CLAUDE.md` files under each root
3. Extract `context_name:` from frontmatter
4. Write/update `~/.claude/names`

Each `CLAUDE.md` declares its own name:

```yaml
---
context_name: systems-geekazoid
---
```

Directory name is the fallback if frontmatter is absent.

### Scanner roots (`~/.claude/scanner-roots`)

```
/workspaces
~/.claude/skills
```

One path per line. Explicit. Not derived from `~` or any hardcoded assumption.

---

## Workspace Root

The system is built off an explicit, userless root — not `~`.

### `~/.claude/config`

```yaml
context_root: /workspaces
max_auto_launch: 3
```

### Layout

```
/workspaces/                     ← context_root
  geekazoid/
    sources/
      systems-geekazoid/
        .claude/
          CLAUDE.md
          MEMORY.md
          STATE.md
          backlog.md
          commands/
      systems-architectures/
        .claude/
          ...
  acme-corp/
    sources/
      ...
  beta-client/
    sources/
      ...
```

Client workspaces are fully isolated. A workspace is portable — zip it, move it, hand it off.

---

## Context Files

Every context directory carries:

| File | Changes | Purpose |
|---|---|---|
| `CLAUDE.md` | Rarely | Persona, project instructions, boot sequence |
| `MEMORY.md` | Slowly | Persistent learnings across sessions |
| `STATE.md` | Every session | Current branch, in-progress work, last decision |
| `backlog.md` | On `/gap` | Captured gaps for this context |

### Boot sequence (in every `CLAUDE.md`)

```markdown
## Session Start

On every session start, read in order if present:
1. `.claude/MEMORY.md`
2. `.claude/STATE.md`
```

CLAUDE.md loads eagerly (auto-loaded by `cd` + `claude`).
MEMORY.md and STATE.md load lazily via the boot sequence.

---

## Session Mechanics

### Wrapper script (`~/bin/cs`)

```bash
#!/bin/bash
CONTEXT=${1:-$HOME}
while true; do
    rm -f ~/.claude/restart-signal
    cd "$CONTEXT" && claude
    [ -f ~/.claude/restart-signal ] || break
    CONTEXT=$(cat ~/.claude/restart-signal)
done
```

Launch sessions via `cs`, not bare `claude`.

### New tab

```bash
guake -e "cs /workspaces/geekazoid/sources/systems-geekazoid" -r "systems-geekazoid"
```

### Restart in same tab (`switch`)

From within a session:

```bash
echo "/workspaces/acme-corp/sources/project-x" > ~/.claude/restart-signal && kill -TERM $PPID
```

Write signal file first, then kill parent (Claude process). Wrapper reads signal and relaunches.

### Launch IDE

```bash
cursor --profile <name> ~/.claude/cursor_workspaces/<name>.code-workspace
```

See **Cursor Workspace Files** section for generation.

### Meta / home context

```bash
cs ~/.claude/home
```

`home` is a minimal context — no project baggage, just the Names registry and verb language. The default starting point. From here any context is one verb away.

---

## Cursor Workspace Files

### Location

```
~/.claude/cursor_workspaces/
  systems-geekazoid.code-workspace          ← canonical (single Name)
  geekazoid-full.code-workspace             ← canonical (named composition)
  acme-full.code-workspace                  ← canonical (named composition)
  .ephemeral/
    a1b2c3.code-workspace                   ← ad-hoc composition, disposable
```

**Two tiers:**

| Tier | How created | In registry | Lifetime |
|---|---|---|---|
| Canonical | Single Name, or `as` alias | Yes | Permanent |
| Ephemeral | Ad-hoc composition, no `as` | No | Until `close` or next session |

Ephemeral files are cleaned up automatically on `close`. The `.ephemeral/` directory is wiped on `cs` startup.

### Format

```json
{
  "folders": [
    { "path": "/workspaces/geekazoid/sources/systems-geekazoid" }
  ],
  "settings": {
    "editor.fontFamily": "Cascadia Mono",
    "workbench.colorTheme": "Default Dark+"
  }
}
```

Multi-folder (composed Names):

```json
{
  "folders": [
    { "path": "/workspaces/geekazoid/sources/systems-geekazoid" },
    { "path": "/workspaces/geekazoid/sources/systems-architectures" }
  ],
  "settings": {
    "editor.fontFamily": "Cascadia Mono",
    "workbench.colorTheme": "Default Dark+"
  }
}
```

### Generation

`generate-workspace.sh <name> [and <name> ...]`

1. Resolve each Name to its path via `~/.claude/names`
2. Build JSON with one `folders` entry per path
3. Apply base settings (font, theme) from `~/.claude/cursor_workspaces/defaults.json`
4. Write to `~/.claude/cursor_workspaces/<name[+name]>.code-workspace`

Idempotent — safe to re-run after adding contexts. Scanner can call it automatically after updating `~/.claude/names`.

### `defaults.json`

```json
{
  "settings": {
    "editor.fontFamily": "Cascadia Mono",
    "editor.fontSize": 14,
    "workbench.colorTheme": "Default Dark+",
    "terminal.integrated.fontFamily": "Cascadia Mono"
  }
}
```

Override per workspace by editing the generated file after generation.

### Launch

```bash
cursor --profile <name> ~/.claude/cursor_workspaces/<name>.code-workspace
```

`--profile` associates a named Cursor profile with the workspace — client-specific extensions and settings persist across opens.

### Names registry addition

The registry gains an optional `workspace_file:` field once generated:

```
systems-geekazoid=/workspaces/geekazoid/sources/systems-geekazoid  context  workspace=~/.claude/cursor_workspaces/systems-geekazoid.code-workspace
```

`start systems-geekazoid --ide` resolves the workspace file and launches Cursor automatically.

---

## Safety — `preview` and Auto-gate

### `preview` verb

```
preview security and all
```

Output:
```
Resolving: security [skill], all [23 contexts]
Would launch: 23 isolated sessions
Contexts: systems-geekazoid, fluffy, acme-corp-api, ...
Est. tokens/session: ~50K
Est. total: ~1.15M tokens
Proceed? [y/N]
```

### Auto-gate

If a verb would spawn more sessions than `max_auto_launch` (default: 3), `preview` behavior is forced. Execution blocked until confirmed.

`all` expansions always trigger the auto-gate.

---

## Security Posture (skill)

Name: `security`
File: `~/.claude/skills/security.md`

Properties:
- **Aware but zero-trust** — subject context is known, nothing in it is trusted
- **Isolated** — subject loaded into a git worktree (isolated copy, no direct writes)
- **Binary at launch**: choose one:
  - `--no-leak` — zero context persistence, no writes, session leaves no trace
  - `--audit` — complete structured log of every action, tool call, and decision
- Destructive actions require explicit per-action confirmation regardless of session permissions

Usage:
```
start security and fluffy
start security and acme-corp --audit
```

---

## `/gap` — Gap Capture

Universal meta-command. Available in every session. Captures missing capabilities to the right backlog.

**Invocation:**
```
/gap [context-name] description of the gap
```

Context name is inferred from current session if omitted.

**Behavior:**
1. Infer or accept context name
2. Append to `<context-path>/.claude/backlog.md`
3. Confirm capture, continue session

**Backlog entry format:**
```markdown
- [ ] YYYY-MM-DD: <description>
```

`/gap` itself lives at `~/.claude/commands/gap.md` and is available globally.

---

## Meta-skill Class: Token Efficiency

Skills that operate on other skills and contexts.

**`token-saver`** — compresses verbose CLAUDE.md, MEMORY.md, or skill files to their load-bearing instructions. Produces a `*-lite.md` variant. Does not modify originals.

**`summarize-memory`** — condenses MEMORY.md before it exceeds limits. Preserves decisions and patterns, drops resolved/stale entries.

These are run explicitly, not automatically:
```
start token-saver and systems-geekazoid
```

---

## Build Order

1. `~/bin/cs` — wrapper script
2. `~/.claude/config` — context_root, max_auto_launch
3. `~/.claude/scanner-roots` + `scan-contexts.sh`
4. `~/.claude/names` — initial manual population, then scanner-maintained
5. `~/.claude/cursor_workspaces/defaults.json` — base Cursor settings
6. `generate-workspace.sh` — workspace file generator
7. `~/.claude/home/CLAUDE.md` — meta/home context
8. `~/.claude/commands/gap.md` — `/gap` skill
9. `~/.claude/commands/start.md` — `start` verb (includes `--ide` flag)
10. `~/.claude/commands/switch.md` — `switch` verb (restart in same tab)
11. `~/.claude/commands/preview.md` — `preview` verb + auto-gate
12. `~/.claude/skills/security.md` — security posture
13. `~/.claude/skills/token-saver.md` — token efficiency meta-skill
