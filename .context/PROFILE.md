# Domain Profile — domain-toolkit

**Generated:** 2026-03-10 (full touch)
**Domain root:** `/home/richard/sources/domain-toolkit`
**Status:** Core pipeline built; distiller prompt is the remaining blocker for end-to-end distillation

> This file is derived. Edit README.md, STATE.md, MEMORY.md, DECISIONS.md, or agent.md instead. Regenerate with `/touch-domain --full`.

---

## What This Domain Is

The **domain-toolkit repo** is the meta-repo for a domain/orchestrator system. It defines the architecture, conventions, and agent skills for managing long-lived work across multiple "domains" (project folders). It is simultaneously the documentation and the implementation of its own conventions.

The core concept is the **domain kit**: the complete set of domain-specific resources an agent is given access to — prompts, personas, context, state, memories, tools, skills — plus a session-distillation loop that gives agents reasoning continuity and humans a feedback gate. Grounded in cybernetics: Ashby's Law of Requisite Variety, Beer's Viable System Model.

---

## Command Taxonomy (four concerns, four commands)

| Command | Concern | Posture |
|---------|---------|---------|
| `touch-domain` | Kit management — health, scaffolding, git, profiling | Objective (from outside) |
| `open-kit` | Viewport launch — opens domain for interactive work | Transition (outside → inside) |
| `checkpoint` | Session capture — structured snapshots during work | Subjective (from inside) |
| `distill` | Memory processing — session artifacts → canonical files | Objective (isolated, debiased) |

`sweep` (the domain sweep) is a **future feature** — System 4 (VSM), strategic attention direction across domains. Deferred until core commands are proven.

---

## Key Components

### Specs (canonical design references)

| File | Purpose |
|------|---------|
| `orchestrator-architecture.md` | Commands, viewport, runtime, hooks, git conventions, implementation path |
| `domain-convention.md` | Domain directory structure, `.context/` file roles, session lifecycle with frontmatter |
| `distiller-spec.md` | Distillation pipeline, access boundaries table, transcript-first processing, `[DOMAIN-TOOLKIT]` marker |
| `.context/domain-toolkit.local.md` | Environment-specific config (Cursor primary, fluffy.geekazoid.net bare repos) |

### Skills (in `.claude/skills/`)

| Skill | Purpose | Status |
|-------|---------|--------|
| `touch-domain` | Universal kit management: validate, scaffold, profile regen, bootstrap, git precheck | Stable |
| `open-kit` | Viewport launch (`--cursor`, `--terminal`) with shell script wrapper | Stable |
| `checkpoint` | Writes structured session checkpoints with YAML frontmatter to `.context/sessions/` | Stable |
| `distill-domain` | Runs distillation pipeline for a single domain | Skill exists, distiller prompt not written |
| `sweep` | Cross-domain attention sweep coordinator | Future |
| `domain-convention` | Reference for domain layout and file roles | Stable |

### Hooks (in `hooks/` — committed and installed globally)

| File | Purpose |
|------|---------|
| `hooks/session-start.sh` | SessionStart hook — injects context files on entry + records session cookie crumb to `session-index.jsonl` |
| `hooks/README.md` | Installation instructions |

Hook reads stdin JSON (session_id, transcript_path, cwd, source). Writes domain-local `session-index.jsonl` if `.context/sessions/` exists. Injects context files if `.context/agent.md` exists.

### Scripts and automation (in `bin/` and `cron/`)

| File | Purpose |
|------|---------|
| `bin/open-kit` | Shell script for viewport launch (`--cursor`, `--terminal`) |
| `bin/stage-transcripts` | Python script: walks registry, extracts CC session JSONL into `.transcript.md` files with thinking blocks |
| `cron/stage-transcripts.cron` | Cron template: runs stager every 15 minutes |
| `cron/distill.cron` | Cron template: runs distillation hourly (pending `bin/distill-pending`) |

### Other files

| File | Purpose |
|------|---------|
| `domain-toolkit.code-workspace` | Cursor/VS Code workspace file for the domain-toolkit domain |
| `~/.claude/domain-toolkit/REGISTRY.md` | Live domain registry with 7 domains (4 with kits, 3 candidates) |
| `doc/REGISTRY.example.md` | Template for registry |
| `verify-assumptions.sh` | Re-runnable runtime assumptions check script |
| `.cursor/rules/domain-toolkit.mdc` | Cursor agent context rules |
| `CLAUDE.md` | Claude Code project instructions |

---

## Architecture

**Two-tier:**
- **Orchestrator** — long-lived, holds registry, manages sweep state
- **Subagents** — ephemeral per-domain, clean context, communicate via filesystem

**Disk is the shared bus.** `.context/` directories are the IPC layer. Everything is interruptible and resumable by design.

**Viewport:** VS Code/Cursor workspace-per-domain via `open-kit --cursor`. Workspace file opens context files as tabs on folderOpen. Entry point: `cursor --new-window domain.code-workspace`.

**Context loading:** `hooks/session-start.sh` — SessionStart hook injects context files deterministically and records session cookie crumb. Installed globally at `~/.claude/hooks/session-start.sh`.

---

## Session Capture Pipeline

```
CC writes JSONL continuously (source of truth, includes thinking blocks)
       ↓
SessionStart hook drops cookie crumb (session_id + transcript_path) → session-index.jsonl
       ↓
bin/stage-transcripts (cron, every 15 min) extracts JSONL → .transcript.md files
  - Tracks byte size in .staged-sessions; re-extracts when session grows
       ↓
Distiller reads transcripts + checkpoints → proposes updates to MEMORY.md / DECISIONS.md
  - Appends [DOMAIN-TOOLKIT] marker to CC JSONL on completion (high-water mark)
  - Marker visible to human and agent if session is resumed
```

### Session lifecycle (frontmatter-tracked)

Checkpoint files carry YAML frontmatter tracking state:
- `status: active` — session in progress
- `status: closed` — session ended, awaiting distillation (cron trigger signal)
- `status: distilled` — processed by distiller

Sessions are **permanent** — never moved, never deleted. The corpus is the durable asset; the distiller is a replaceable lens. Re-distillation is always possible by removing the `[DOMAIN-TOOLKIT]` marker.

**Cron** is the primary distillation trigger — decoupled from Claude Code process lifecycle.

### Access boundaries

| Actor | Session transcripts | Checkpoints | Canonical files | CC JSONL |
|-------|-------------------|-------------|-----------------|----------|
| **Working agent** | Never reads/writes | Writes (append-only, `/checkpoint`) | Reads on entry. Never writes. | CC runtime writes; agent unaware |
| **Stager** | Writes (extracts from JSONL) | Never touches | Never touches | Reads (source of truth) |
| **Distiller** | Reads (primary input) | Reads (attention markers) | Writes proposed updates | Appends `[DOMAIN-TOOLKIT]` marker |
| **Human** | Can author directly | Can author directly | Approves distiller proposals | Sees marker on resume |

---

## Distillation

`claude -p` with `--system-prompt-file` — headless, isolated, no shared session history. The disk boundary between working agent and distiller is a debiasing mechanism. Three perspectives model: distiller forms independent view, then weighs against human and agent checkpoints. Opus-tier by default.

**Distiller prompt (`distiller-prompt.md`) not yet written** — primary blocker for end-to-end distillation.

---

## Key Decisions (highlights — see DECISIONS.md for full rationale)

| Decision | Summary |
|----------|---------|
| Disk as shared bus | No in-memory subagent comm; interruptibility by design |
| Serial sweep | Full attention per domain; parallelism reserved for touch --full |
| Skills over scripts | Claude Code project-local skills as primary implementation |
| Staged writes | Agents never write directly to MEMORY/DECISIONS; all via distiller |
| VS Code workspace viewport | Replaced tmux/neovim — no custom glue needed |
| Claude Code hooks for context loading | Deterministic SessionStart hooks, not LLM-dependent |
| Headless `claude -p` for distillation | Clean context isolation; disk boundary = debiasing |
| Agent teams NOT used | Teams share working dir — wrong primitive for domain isolation |
| touch as modal command | One command: smart default + --full/--new/--all/--no-touchy/-y flags |
| Git-aware by default | All domains git-tracked; touch surfaces, not silently fixes |
| Four commands, four concerns | Clean separation: each command evolves independently |
| Domain kit as foundational concept | VSM-grounded, not just "context engineering" |
| CC JSONL as source of truth | Transcripts derived from CC's native session files; never modified except `[DOMAIN-TOOLKIT]` marker |
| Three perspectives distillation | Distiller forms own view, then weighs human + agent perspectives |
| Opus for distillation | Judgment-heavy, not summarization |
| Sessions are permanent, distillation rerunnable | Corpus is durable asset; distiller is a replaceable lens |
| Frontmatter over file suffixes | Session lifecycle tracked in YAML frontmatter, not filenames or `processed/` folder |
| Cron as primary distillation trigger | Decoupled from CC process lifecycle; signal is `closed` sessions on disk |

---

## Current Status

Core pipeline built and validated across multiple sessions. Distiller spec substantially revised: access boundaries table, frontmatter lifecycle (replacing `processed/` folder), permanent sessions, cron trigger model. Auto-run-command extension evaluated for VS Code workspace auto-launch.

**What's done:**
- All four command specs complete and consistent
- Runtime verified — Claude Code CLI, Cursor CLI, SSH/bare repo, workspace tasks
- SessionStart hook committed, installed, and working (session indexing + context injection)
- `/touch-domain` and `/open-kit` skills fully implemented
- Domain registry live with 7 domains
- Session capture pipeline: hook → JSONL → stager → transcript.md (with thinking blocks)
- `[DOMAIN-TOOLKIT]` marker format validated; acts as high-water mark for incremental distillation
- Distiller spec revised: access boundaries table, frontmatter lifecycle, permanent sessions, cron trigger
- `domain-convention.md` updated: removed `processed/` folder, added frontmatter lifecycle
- Cron templates for staging and distillation
- Test domain (`touchy-muchy`) bootstrapped and validated

**What's next (priority order):**
1. Write distiller prompt (`distiller-prompt.md`) — primary blocker for headless distillation
2. Implement `bin/distill-pending` — cron-driven distillation runner
3. Run first distillation (domain-toolkit domain itself — MEMORY.md is stale)
4. Install cron jobs (localize templates, add to crontab)
5. End-to-end test: full lifecycle through a real domain

---

## Gaps & Warnings

1. **MEMORY.md is stale** — references Alacritty+tmux runtime, says transcript capture undecided (now decided), missing frontmatter lifecycle and other session decisions. Distillation needed.
2. **Distiller prompt not written** — `distiller-prompt.md` doesn't exist; headless distillation can't run yet.
3. **`bin/distill-pending` not written** — cron-driven distiller runner doesn't exist yet.
4. **Cron jobs not installed** — templates exist in `cron/`, need localization and `crontab` installation.
5. **Uncommitted changes** — `.context/sessions/session-index.jsonl` has local modifications.
