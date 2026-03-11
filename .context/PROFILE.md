# Domain Profile — firehose

**Generated:** 2026-03-10 (full touch)
**Domain root:** `/home/richard/sources/firehose`
**Status:** Skills being updated — `/touch` rewritten, `open-kit` next

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
| `distiller-spec.md` | Distillation pipeline, isolation requirement, strategies, review gate |
| `firehose.local.md` | Environment-specific config (Cursor primary, LiteLLM gateway, bare repo server) |

### Skills (in `.claude/skills/`)

| Skill | Purpose | Status |
|-------|---------|--------|
| `touch` | Universal kit management: validate, scaffold, profile regen, bootstrap, git precheck | **Updated this session** — modal modes, git precheck, `--all` sweep |
| `checkpoint` | Writes structured session checkpoints to `.context/sessions/` | Stable |
| `distill-domain` | Runs distillation pipeline for a single domain | Stable |
| `firehose` | Serial sweep coordinator | Future |
| `domain-convention` | Reference for domain layout and file roles | Stable |

### Hooks (in `hooks/` — committed and installed)

| File | Purpose |
|------|---------|
| `hooks/session-start.sh` | SessionStart hook — injects context files on entry if `.context/agent.md` present |
| `hooks/README.md` | Installation instructions |

Hook is installed globally at `~/.claude/hooks/session-start.sh` (thin wrapper delegating to repo copy). Confirmed working.

### Other files

| File | Purpose |
|------|---------|
| `firehose.code-workspace` | VS Code workspace file for the firehose domain itself |
| `firehose/REGISTRY.example.md` | Template for live REGISTRY.md — no live registry yet |
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

**Context loading:** `hooks/session-start.sh` — SessionStart hook that injects context files deterministically. Installed and working.

**Distillation:** `claude -p` with `--system-prompt-file` — headless, isolated, no shared session history. Disk boundary is the debiasing mechanism.

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

---

## Current Status

**`/touch` skill rewritten this session.** Modal modes (default, --full, --new, --all), git precheck (6 states), --no-touchy and -y modifiers. `touch-full-domain` removed — `/touch` is the single command. `--full` without a path no longer implies "all domains" — that's `--all` (with mandatory cost warning).

**Test domain bootstrapped:** `/touch --new ~/sources/touchy-muchy` — validated the onboarding flow end-to-end.

**What's done:**
- All four command specs complete and consistent
- Runtime verified — Claude Code CLI, Cursor CLI, SSH/bare repo, workspace tasks
- SessionStart hook committed, installed, and working
- `/touch` skill fully rewritten with all modes
- Test domain (`touchy-muchy`) bootstrapped successfully

**What's next (priority order):**
1. Implement `open-kit` skill (`--cursor`, `--terminal`)
2. Write REGISTRY.md (live registry)
3. Write distiller prompt (`distiller-prompt.md`)
4. Design global config format (`~/.firehose/config.md`)
5. End-to-end test: full lifecycle through a real domain

---

## Gaps & Warnings

1. **MEMORY.md is stale** — still says Alacritty+tmux runtime, says no README.md exists. Distillation needed.
2. **`open-kit` not implemented** — spec complete, no skill exists yet.
3. **No live REGISTRY.md** — `firehose/REGISTRY.example.md` is a template only. Needed for `--all` sweep.
4. **Distiller prompt not written** — `distiller-prompt.md` doesn't exist; headless distillation can't run yet.
5. **`sessions/processed/` empty** — no sessions have been through distillation yet.
6. **`variety-agent-design.md` lives in `cursus`** — decision pending: copy here or reference externally.
7. **Unpushed commits** — 1 commit ahead of origin, plus uncommitted changes from this session.
