# Domain Profile — firehose

**Generated:** 2026-03-10 (full touch)
**Domain root:** `/home/richard/sources/firehose`
**Status:** Session capture pipeline built, distiller spec updated, approaching first end-to-end distillation

> This file is derived. Edit README.md, STATE.md, MEMORY.md, DECISIONS.md, or agent.md instead. Regenerate with `/touch --full`.

---

## What This Domain Is

The **firehose repo** is the meta-repo for a domain/orchestrator system. It defines the architecture, conventions, and agent skills for managing long-lived work across multiple "domains" (project folders). It is simultaneously the documentation and the implementation of its own conventions.

The core concept is the **domain kit**: the complete set of domain-specific resources an agent is given access to — prompts, personas, context, state, memories, tools, skills — plus a session-distillation loop that gives agents reasoning continuity and humans a feedback gate. Grounded in cybernetics: Ashby's Law of Requisite Variety, Beer's Viable System Model.

---

## Command Taxonomy (four concerns, four commands)

| Command | Concern | Posture |
|---------|---------|---------|
| `touch` | Kit management — health, scaffolding, git, profiling | Objective (from outside) |
| `open-kit` | Viewport launch — opens domain for interactive work | Transition (outside -> inside) |
| `checkpoint` | Session capture — structured snapshots during work | Subjective (from inside) |
| `distill` | Memory processing — session artifacts -> canonical files | Objective (isolated, debiased) |

`firehose` (the sweep) is a **future feature** — System 4 (VSM), strategic attention direction across domains. Deferred until core commands are proven.

---

## Key Components

### Specs (canonical design references)

| File | Purpose |
|------|---------|
| `orchestrator-architecture.md` | Commands, viewport, runtime, hooks, git conventions, implementation path |
| `domain-convention.md` | Domain directory structure, `.context/` file roles, session lifecycle |
| `distiller-spec.md` | Distillation pipeline, three perspectives model, transcript-first processing, `[FIREHOSE]` marker |
| `firehose.local.md` | Environment-specific config (Cursor primary, LiteLLM gateway, bare repo server) |

### Skills (in `.claude/skills/`)

| Skill | Purpose | Status |
|-------|---------|--------|
| `touch` | Universal kit management: validate, scaffold, profile regen, bootstrap, git precheck | Stable |
| `open-kit` | Viewport launch (`--cursor`, `--terminal`) with shell script wrapper | Stable |
| `checkpoint` | Writes structured session checkpoints to `.context/sessions/` | Stable |
| `distill-domain` | Runs distillation pipeline for a single domain | Skill exists, distiller prompt not written |
| `firehose` | Serial sweep coordinator | Future |
| `domain-convention` | Reference for domain layout and file roles | Stable |

### Hooks (in `hooks/` — committed and installed)

| File | Purpose |
|------|---------|
| `hooks/session-start.sh` | SessionStart hook — injects context files on entry + records session cookie crumb to `session-index.jsonl` |
| `hooks/README.md` | Installation instructions |

Hook reads stdin JSON from CC (session_id, transcript_path, cwd, source). Writes domain-local session index if `.context/sessions/` exists. Then injects context files if `.context/agent.md` exists.

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
| `firehose.code-workspace` | VS Code workspace file for the firehose domain itself |
| `firehose/REGISTRY.md` | Live domain registry with 7 domains (4 with kits, 3 candidates) |
| `firehose/REGISTRY.example.md` | Template for registry |
| `verify-assumptions.sh` | Re-runnable runtime assumptions check script |
| `.cursor/rules/firehose.mdc` | Cursor agent context rules |
| `CLAUDE.md` | Claude Code project instructions |

---

## Architecture

**Two-tier:**

- **Orchestrator** — long-lived, holds registry, manages sweep state
- **Subagents** — ephemeral per-domain, clean context, communicate via filesystem

**Disk is the shared bus.** `.context/` directories are the IPC layer. Everything is interruptible and resumable by design.

**Viewport:** VS Code workspace-per-domain via `open-kit --cursor`. Workspace file auto-opens context files as tabs. Entry point: `cursor --new-window domain.code-workspace`.

**Context loading:** `hooks/session-start.sh` — SessionStart hook that injects context files deterministically and records session cookie crumb. Installed and working.

**Session capture pipeline:**
1. SessionStart hook drops cookie crumb (session_id + transcript_path) in domain's `session-index.jsonl`
2. CC writes JSONL continuously during session (source of truth, includes thinking blocks)
3. `bin/stage-transcripts` (cron) extracts JSONL into readable `.transcript.md` files
4. Stager tracks JSONL byte size in `.staged-sessions` — re-extracts when session grows
5. Distiller reads transcripts + checkpoints, appends `[FIREHOSE]` marker to CC JSONL on completion
6. `[FIREHOSE]` marker visible in CC conversation view if session is resumed

**Distillation:** `claude -p` with `--system-prompt-file` — headless, isolated, no shared session history. Three perspectives model: distiller forms independent view, then weighs against human and agent checkpoints. Opus-tier by default.

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
| Git-aware by default | All domains git-tracked; bare repo convention; touch surfaces, not silently fixes |
| Four commands, four concerns | Clean separation: each command evolves independently |
| Domain kit as foundational concept | VSM-grounded, not just "context engineering" |
| CC JSONL as source of truth | Transcripts derived from CC's native session files, never modified except `[FIREHOSE]` marker |
| Three perspectives distillation | Distiller forms own view, then weighs human + agent perspectives. Best truth wins. |
| Opus for distillation | Judgment-heavy, not summarization. Downgrade when proven prompt exists. |

---

## Current Status

**Session capture pipeline built this session.** SessionStart hook updated to record cookie crumbs. `bin/stage-transcripts` extracts CC JSONL into `.transcript.md` files with thinking blocks. `[FIREHOSE]` distillation marker format tested and confirmed visible in CC conversation view. Distiller spec updated with transcript-first processing, three perspectives model, and `[FIREHOSE]` marker convention.

**What's done:**
- All four command specs complete and consistent
- Runtime verified — Claude Code CLI, Cursor CLI, SSH/bare repo, workspace tasks
- SessionStart hook committed, installed, and working (now with session indexing)
- `/touch` and `/open-kit` skills fully implemented
- Domain registry live with 7 domains
- Session capture pipeline: hook -> JSONL -> stager -> transcript.md
- `[FIREHOSE]` marker format validated (appended to CC JSONL, visible in conversation view)
- Distiller spec substantially updated (transcript-first, three perspectives, Opus default)
- Cron templates for staging and distillation
- Test domain (`touchy-muchy`) bootstrapped and validated

**What's next (priority order):**
1. Write distiller prompt (`distiller-prompt.md`) — enables headless `claude -p` distillation
2. Implement `bin/distill-pending` — cron-driven distillation runner
3. Run first distillation (firehose domain itself — MEMORY.md is stale)
4. Install cron jobs (localize templates)
5. End-to-end test: full lifecycle through a real domain

---

## Gaps & Warnings

1. **MEMORY.md is stale** — references Alacritty+tmux runtime, says transcript capture undecided (now decided). Distillation needed.
2. **Distiller prompt not written** — `distiller-prompt.md` doesn't exist; headless distillation can't run yet.
3. **`bin/distill-pending` not written** — cron-driven distiller runner doesn't exist yet.
4. **Cron jobs not installed** — templates exist in `cron/`, need localization and `crontab` installation.
5. **`sessions/processed/` empty** — no sessions have been through distillation yet.
6. **`variety-agent-design.md` lives in `cursus`** — decision pending: copy here or reference externally.
7. **Unpushed commits** — 2 commits ahead of origin, plus uncommitted changes from this session.
8. **STATE.md is stale** — still references open threads that are now resolved (session capture decided, open-kit implemented).
