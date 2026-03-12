# Domain Kit Architecture

## Overview

This system provides infrastructure for durable human-agent collaboration across a constellation of **domains** — folders representing concerns of varying scope and lifespan. Each domain carries a **domain kit**: prompts, personas, context, state, memories, and a session-distillation loop that gives agents reasoning continuity and humans a feedback gate.

The **domain kit** (a term coined in this project) refers to the combination of all domain-specific resources that a model is given access to — inclusive of tools, skills, context files, agent configuration, and accumulated state. It is the basic unit of governance in the system. Grounded in cybernetics (Ashby's Law of Requisite Variety, Beer's Viable System Model).

The architecture separates three concerns into three commands:

- **`touch-domain`** — kit management. Structural health, git state, profiling, scaffolding, bootstrapping. Operates from the outside, objectively.
- **`open-domain`** — viewport launch. Opens a managed domain for interactive work in a specified viewport. The transition from objective to subjective.
- **`distill`** — memory processing. Transforms session artifacts into canonical domain knowledge. Runs in isolated context — objective, debiased.

The disk is the shared bus. Agents do not talk to each other or to the orchestrator in memory. They read from and write to the domain's `.context/` directory. This ensures clean context isolation and makes the system interruptible and resumable by design.

## Domain Registry

The orchestrator maintains a **registry** — a map of all known domains. This is the input to every orchestrator command. The registry contains:

- Domain path (folder location)
- Domain name / identifier
- Last touched timestamp
- Structural health (does `.context/` exist and validate?)
- Profile currency (when was PROFILE.md last generated?)

The registry is a file on disk (format TBD — likely markdown or YAML). It is the single source of truth for what domains exist and their orchestrator-level metadata.

## Commands

### `touch-domain`

The universal entry point for any domain interaction. Modal — determines what's needed based on the state of the target path and acts accordingly.

**Modes:**

**Default (no flags)** — Smart touch. Inspects the target path and picks the right action:
- Path doesn't exist or has no `.context/`: prompts "This doesn't exist as a domain. Create it? (use `touch-domain --new`)"
- Path exists, `.context/` exists but PROFILE.md is stale or missing: suggests `touch-domain --full`
- Path exists, `.context/` healthy: runs lightweight structural validation
- In all cases, checks git status if the domain is a git repo (uncommitted changes, unpushed commits, remote configuration, worktree state)

**What the default touch validates:**
- `.context/` directory exists with required files: agent.md, STATE.md, MEMORY.md, DECISIONS.md
- Pointer integrity in agent.md (do referenced files exist?)
- Git status: clean working tree, remotes configured per convention, no detached HEAD or mid-rebase state
- `domain.code-workspace` exists and is current
- Reports structural health including git concerns

**Characteristics:**
- Fast, cheap, parallelizable
- No content reading or synthesis (unless escalating to --full)
- Idempotent — can create missing scaffolding or just validate
- Can run across the entire registry as a preflight check
- Surfaces concerns rather than silently fixing them

**`touch-domain --full`** — Full profile regeneration.
- Everything default touch does, plus:
- Reads README.md, STATE.md, agent.md, MEMORY.md, DECISIONS.md
- Scans the domain's repo/folder contents
- Generates or updates PROFILE.md
- Generates or updates `domain.code-workspace`
- Expensive — requires a model call per domain
- Parallelizable with configurable concurrency limits
- Each domain gets a clean subagent context (no cross-domain bleed)

**`touch-domain --new`** — New domain bootstrapping.
- Creates the domain directory if it doesn't exist
- Kicks off an interactive onboarding session: what is this domain, scope, agent persona, initial concerns
- That onboarding conversation is captured as the first session in `.context/sessions/`
- From the session, creates: directory structure, README.md, agent.md, `.context/` scaffolding, initial STATE.md
- Initializes git repo per global conventions (see Git Conventions below)
- Runs `--full` at the end to generate PROFILE.md and `domain.code-workspace`
- Opens the domain viewport: `code --new-window domain.code-workspace`
- The domain is born version-controlled, context-aware, and ready for work

**Modifier flags:**

**`--no-touchy`** — Pure read-only diagnostic. Reports everything the default touch would report — structural health, git state, staleness, concerns — but writes nothing. No scaffolding fixes, no file generation, no git operations. Just the report. Composes with other modes: `touch-domain --full --no-touchy` tells you what a full touch *would* do. `touch-domain --new --no-touchy` on a nonexistent path tells you what bootstrapping would create.

**`-y`** — Suppress prompts. Auto-confirms for git states Ahead, No remote, and Not a repo. Diverged and Behind still block even with `-y`, because syncing when diverged or stale would make things worse. Useful for automation and sweeps where you've already decided "yes, sync everything."

**The command is designed for extensibility.** Future `--options` will emerge as the system matures. The modal default (inspect state, pick the right action, prompt if ambiguous) is the stable interface — flags are explicit overrides.

**Usage:**
```
touch-domain <path>              # smart touch — validates, suggests escalation if needed
touch-domain --full <path>       # full profile regeneration
touch-domain --all               # full touch all domains in registry (warns first)
touch-domain --new <path>        # new domain bootstrapping
touch-domain --new               # new domain bootstrapping (prompts for path)
touch-domain --no-touchy <path>  # read-only diagnostic, no writes
touch-domain -y <path>           # suppress prompts (auto-confirm safe operations)
```

### Git Conventions

Domains that are git repos follow a standard remote configuration, defined globally with per-domain overrides.

**Global defaults** (configured in `~/.claude/domain-toolkit/config.md` or similar):
- **Origin**: bare repo on a configured primary server (host, path pattern defined in local config)
- **Mirror**: optional secondary remote (e.g., GitHub private repo, per-domain opt-in)
- **Branch conventions**: TBD per domain needs

**Per-domain overrides** in `agent.md`:
- Domains can specify non-standard remotes, additional mirrors, or explicit exemption from the bare-repo requirement (`git_remote: none` or `git_remote: local-only`)

**Git state precheck** — runs before any touch logic. The state is always surfaced to the user:

| State | Condition | Action |
|-------|-----------|--------|
| **Diverged** | Local and remote have divergent commits | Surface it. Open in IDE to resolve. No writes until resolved. |
| **Behind** | Remote is ahead of local | Prompt: "Canonical version is on the server. Work on that or pull here?" No writes until resolved. |
| **Ahead** | Local has unpushed commits | Proceed with touch, surface concern. Prompt to push. |
| **Clean** | In sync with remote | Proceed normally. |
| **No remote** | Repo exists but no remote configured | Proceed with touch. Prompt to create bare remote, unless exempted in agent.md. If exempted, note it informationally. |
| **Not a repo** | No `.git/` directory | Proceed with touch. Prompt to initialize, unless exempted. |

States **Diverged** and **Behind** block writes — touching would create conflicts or be immediately stale. All other states proceed but surface concerns.

The `-y` flag auto-confirms prompts for states 3-6. States 1 and 2 still block even with `-y`.

**What touch checks (git housekeeping):**
- Git state (see table above)
- Is there a remote origin? Does it match the expected convention?
- Is the bare repo on the configured server reachable / does it exist?
- Uncommitted changes? Unpushed commits? Stale branches?
- Worktree state: detached HEAD, mid-rebase, merge conflicts?
- All concerns surfaced in the touch report — not silently fixed

**What `--new` does for git:**
- `git init` in the new domain directory
- Prompts to create bare repo on configured server
- Configures origin remote
- Initial commit with scaffolding
- Optionally creates secondary mirror if configured

### `open-domain`

Launch a domain viewport for interactive work. This is the transition from objective (managing kits from the outside) to subjective (working within a domain's context).

**What it does:**
- Opens the domain's `domain.code-workspace` in the specified viewport
- Context files appear as tabs, Claude Code launches with the domain's agent prompt
- The agent runs touch, briefs the human on domain state and concerns
- The human is in discourse — the session is live

**Viewport targets:**

```
open-domain <domain> --cursor     # opens in Cursor / VS Code
open-domain <domain> --terminal   # opens in Claude Code terminal (no IDE)
```

Additional viewport targets can be added as the system evolves (e.g., `--cowork` if Cowork gains programmatic session creation).

**Characteristics:**
- Always opens a fresh, isolated context window per domain — no cross-domain bleed
- The workspace file controls what files are visible and what Claude Code session starts
- Can be invoked from the orchestrator terminal, from a script, or from another session
- Session logging is active from the moment the viewport opens

**Usage:**
```
open-domain cashflow --cursor      # open cashflow in Cursor/VS Code
open-domain cashflow --terminal    # open cashflow in terminal Claude Code
open-domain --cursor               # prompts for domain selection
```

### `/map`

Display and manage the domain registry.

**What it does:**
- Shows the registry as a navigable text view
- Displays structural health, profile currency, last-touched timestamps
- Supports filtering, sorting, grouping
- Allows adding/removing/reorganizing domains

**Characteristics:**
- Read-only by default (display mode)
- Can be combined with touch as a preflight: `/map` after `touch-domain` shows current health

**Usage:**
```
/map                       # display full registry
/map --stale               # show domains with outdated profiles
/map --add <path>          # register a new domain
/map --remove <domain>     # unregister a domain
```

### Sweep (future)

A sweep across all domains that surfaces what needs attention. This is a System 4 function (in VSM terms) — intelligence, looking outward and forward. Not yet specified in detail.

**Intent:** scan the registry, run `touch-domain --no-touchy` across all domains, and produce a prioritized briefing: "Here's what really needs your attention right now." Surfaces stale profiles, unprocessed sessions, met revisit conditions, git concerns, domains that haven't been touched in a while.

**Not the same as** sequentially opening every domain for interactive work. The sweep is objective attention-direction. `open-domain` is subjective engagement. The sweep tells you *which* kit to open.

**Design deferred** until the core commands (`touch-domain`, `open-domain`, `distill`) are proven in daily use.

## Domain Viewport

Each domain opens as its own VS Code window via `open-domain <domain> --cursor`. Under the hood, this opens the domain's `.code-workspace` file. The workspace file is a living artifact — generated and maintained by `touch-domain --full`.

The viewport surfaces four areas:

| Surface | How | Temporal Character |
|---------|-----|-------------------|
| PROFILE.md | Auto-opened tab (markdown preview) | Derived, regenerated |
| MEMORY.md | Auto-opened tab | Grows over time, distilled |
| DECISIONS.md | Auto-opened tab | Append-only, structured |
| Agent Chat | Claude Code in integrated terminal | Ephemeral |

Additional files of concern are surfaced during the session — the working agent calls `code <file>` via Bash to open them as tabs in the same window.

**Read direction** (entering a domain): Profile → Memory → Decisions → Chat
**Write direction** (leaving a domain): Chat → Session artifacts → Distiller → Memory + Decisions → Profile (next touch --full)

### Workspace File

Each domain has a `domain.code-workspace` file at its root, generated by `touch-domain --full`:

```json
{
  "folders": [
    { "path": "." },
    { "path": ".context", "name": "Domain Context" }
  ],
  "tasks": {
    "version": "2.0.0",
    "tasks": [
      {
        "label": "Open Domain Context",
        "type": "shell",
        "command": "code .context/PROFILE.md .context/STATE.md .context/MEMORY.md .context/DECISIONS.md",
        "presentation": { "reveal": "silent" },
        "runOptions": { "runOn": "folderOpen" }
      },
      {
        "label": "Start Domain Session",
        "type": "shell",
        "command": "claude --append-system-prompt-file .claude/agent.md 'Run /touch-domain --full and brief me'",
        "presentation": { "reveal": "always", "panel": "new" },
        "runOptions": { "runOn": "folderOpen" }
      }
    ]
  },
  "settings": {}
}
```

The entry point from anywhere — terminal, script, another session — is:

```bash
open-domain cashflow --cursor
# which resolves to: code --new-window /path/to/cashflow/domain.code-workspace
```

VS Code opens a new window. Context files appear as tabs. Claude Code launches in the extension panel with the domain's agent prompt and runs touch. The human is in discourse.

## Subagent Lifecycle

1. **Spawn**: `open-domain <domain> --cursor` opens the domain viewport, which launches Claude Code with `--append-system-prompt-file .claude/agent.md`
2. **Bootstrap**: Claude Code's `SessionStart` hook reads agent.md, loads context per the context map. Context files auto-open as tabs via workspace `folderOpen` task.
3. **Execute**: Interactive session — the agent performs its task, surfaces files of concern via `code <file>`
4. **Close**: Session ends, VS Code window can be closed
5. **Distill**: Headless `claude -p` processes session artifacts in isolated context (separate invocation, no session history)

## Concurrency

- `touch-domain` (light): highly parallelizable, no model calls, limited only by filesystem
- `touch-domain --full`: parallelizable with configurable concurrency cap (N simultaneous subagents)
- `open-domain`: one domain at a time per viewport, but multiple viewports can be open simultaneously
- `distill`: can run in background, async, or batched — no contention with interactive sessions

Concurrency limits are configurable at the orchestrator level (not per-domain).

## Real-Time Monitoring

For parallel operations (touch --full across many domains), the orchestrator should provide:

- Visibility into what subagents are doing
- Ability to cancel individual subagents
- Status updates as domains complete

Implementation: headless `claude -p` invocations for non-interactive work (touch --full, distillation) write status to a shared file or use Claude Code's native session persistence. The coordination session (or a simple script) polls completion. For interactive work, each domain has its own VS Code window — the window itself is the visibility.

## Persistence and Resumability

All orchestrator state is disk-backed:

- **Registry**: domain list and metadata
- **Sweep state**: sweep progress (which domains done, which pending, current phase)
- **Session state**: session artifacts within a domain
- **Canonical context**: MEMORY.md, DECISIONS.md, PROFILE.md

Nothing critical lives only in memory. Any process can be interrupted (ctrl-c, crash, "I'm going to lunch") and resumed from the last disk state or sweep position.

## Runtime Environment

### Environment

| Layer | Tool | Role |
|-------|------|------|
| Editor / viewport | VS Code (Cursor-compatible) | Windows, tabs, splits, markdown preview, file explorer |
| Agent runtime | Claude Code (CLI + VS Code extension) | Interactive sessions, skills, hooks, subagents |
| Agent runtime (headless) | `claude -p` (print mode) | Non-interactive work: touch --full, distillation |
| Desktop | User's local environment | Host environment |

The orchestrator runs as local user. No containers, no remote execution.

### Subagent Runtime

Interactive sessions are Claude Code running in VS Code's integrated terminal, one per domain window. Non-interactive work (parallel touch --full, distillation) uses headless `claude -p` invocations.

Session logging uses Claude Code's native session persistence. Sessions are identified by `--session-id <uuid>` for deterministic tracking. Optionally, the `claudeProcessWrapper` VS Code setting can point at a script that tees session output to `.context/sessions/<timestamp>.log` for the distiller's raw log input.

### VS Code as the Body

VS Code is the primary workspace. Each domain opens as its own window via `domain.code-workspace`. Three modes of use:

**Interactive mode.** A VS Code window with the domain's workspace file loaded. Claude Code runs in the integrated terminal. Context files are open as editor tabs (with markdown preview available). The agent surfaces additional files of concern by calling `code <file>` via Bash during the session.

**Editing mode.** Standard VS Code editing. `.context/` files open as tabs, editable with full markdown support. Split views, multi-monitor layouts, and the file explorer provide navigation. This is where you review `.proposed` files, edit MEMORY.md, and approve distiller output.

**Background mode.** Headless `claude -p` invocations for non-interactive work. Parallel touch --full across the registry, batch distillation, any autonomous subagent work. Results are written to disk and reviewed in editing mode.

### Domain Viewport in VS Code

Each domain gets a **window** in VS Code. The workspace file controls:

- Which folders are visible (domain root + `.context/`)
- Which files auto-open as tabs on entry (PROFILE.md, STATE.md, MEMORY.md, DECISIONS.md)
- A `folderOpen` task that launches Claude Code with the domain's agent prompt

```
┌─────────────────────────────────────┬──────────────────────────┐
│                                     │  PROFILE.md              │
│                                     │  (editor tab / preview)  │
│   Claude Code                       ├──────────────────────────┤
│   (integrated terminal)             │  MEMORY.md               │
│                                     │  (editor tab)            │
│                                     ├──────────────────────────┤
│                                     │  DECISIONS.md            │
│                                     │  (editor tab)            │
└─────────────────────────────────────┴──────────────────────────┘
```

The OS window list / taskbar serves as the sweep history. Completed domains stay as open windows. Each window is isolated — no context leakage between domains.

### Hooks

Claude Code hooks provide deterministic automation at session lifecycle points:

**`SessionStart` hook**: fires when Claude Code starts a session. Reads `.context/PROFILE.md → MEMORY.md → DECISIONS.md → STATE.md` and injects the content as opening context. The read-on-entry flow becomes automatic.

**`Stop` hook**: fires when the agent finishes a response. Can be used to write structured session summaries to `.context/sessions/`.

**`PostToolUse` hook**: can enforce domain-specific constraints (e.g., prevent writes to canonical files).

## Implementation Path

**Phase 1 — Core Commands:**
- `touch-domain`: structural validation, git precheck, scaffolding, `--full` profile regeneration, `--new` domain bootstrapping
- `open-domain --cursor`: viewport launch via workspace files
- Domain registry as a markdown file
- `SessionStart` hook for automatic context loading
- Session logging via Claude Code native session persistence

**Phase 2 — Memory Lifecycle:**
- `distill`: headless `claude -p` with distillation system prompt, isolated context
- `Stop` hook or post-session script triggers distillation
- `claudeProcessWrapper` for session transcript capture (feeds distiller)
- Parallel `touch-domain --full` via headless `claude -p` with concurrency cap
- Review gate workflow for `.proposed` files

**Phase 3 — Attention Direction:**
- Sweep: scan registry, surface what needs attention, prioritized briefing
- Cross-domain search across all `.context/` files
- Sweep analytics (time per domain, decision velocity, etc.)
- Workspace file evolution: touch updates which files are surfaced based on current concerns
