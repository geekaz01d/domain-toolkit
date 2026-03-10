

# Domain Profile — firehose

**Generated:** 2026-03-10 (full touch)
**Domain root:** `/home/richard/sources/firehose`
**Status:** SessionStart hook implemented — skill implementation is the active frontier

---

## What This Domain Is

The **firehose repo** is the meta-repo for a domain/orchestrator system. It defines the architecture, conventions, and agent skills for managing long-lived work across multiple "domains" (project folders). It is simultaneously the documentation and the implementation of its own conventions.

The core concept is the **domain kit**: the complete set of domain-specific resources an agent is given access to — prompts, personas, context, state, memories, tools, skills — plus a session-distillation loop that gives agents reasoning continuity and humans a feedback gate. Grounded in cybernetics: Ashby's Law of Requisite Variety, Beer's Viable System Model.

---

## Command Taxonomy (four concerns, four commands)


| Command        | Concern                                                 | Posture                        |
| -------------- | ------------------------------------------------------- | ------------------------------ |
| `touch-domain` | Kit management — health, scaffolding, git, profiling    | Objective (from outside)       |
| `open-kit`     | Viewport launch — opens domain for interactive work     | Transition (outside → inside)  |
| `checkpoint`   | Session capture — structured snapshots during work      | Subjective (from inside)       |
| `distill`      | Memory processing — session artifacts → canonical files | Objective (isolated, debiased) |


`firehose` (the sweep) is a **future feature** — System 4 (VSM), strategic attention direction across domains. Deferred until core commands are proven.

---

## Key Components

### Specs (canonical design references)


| File                           | Purpose                                                                         |
| ------------------------------ | ------------------------------------------------------------------------------- |
| `orchestrator-architecture.md` | Commands, viewport, runtime, hooks, git conventions, implementation path        |
| `domain-convention.md`         | Domain directory structure, `.context/` file roles, session lifecycle           |
| `distiller-spec.md`            | Distillation pipeline, isolation requirement, strategies, review gate           |
| `firehose.local.md`            | Environment-specific config (Cursor primary, LiteLLM gateway, bare repo server) |


### Skills (in `.claude/skills/`)


| Skill               | Purpose                                                       | Notes                                    |
| ------------------- | ------------------------------------------------------------- | ---------------------------------------- |
| `touch-domain`      | Structural validation and scaffolding                         | Needs update: modal modes + git precheck |
| `touch-full-domain` | Full touch: reads context, scans, regenerates PROFILE.md      | Needs update: modal modes                |
| `checkpoint`        | Writes structured session checkpoints to `.context/sessions/` | Stable                                   |
| `distill-domain`    | Runs distillation pipeline for a single domain                | Stable                                   |
| `firehose`          | Serial sweep coordinator                                      | Future                                   |
| `domain-convention` | Reference for domain layout and file roles                    | Stable                                   |


### Hooks (in `hooks/` — implemented, **not yet installed**)


| File                     | Purpose                                                                           |
| ------------------------ | --------------------------------------------------------------------------------- |
| `hooks/session-start.sh` | SessionStart hook — injects context files on entry if `.context/agent.md` present |
| `hooks/README.md`        | Installation: copy to `~/.claude/hooks/`, add entry to `~/.claude/settings.json`  |


Hook script is written. Not committed to git. Not installed on this machine yet.

### Other files


| File                                                    | Purpose                                                     |
| ------------------------------------------------------- | ----------------------------------------------------------- |
| `firehose.code-workspace`                               | VS Code workspace file (untracked, not committed)           |
| `firehose/REGISTRY.example.md`                          | Template for live REGISTRY.md — no live registry yet        |
| `.context/sessions/2026-03-10-cowork-assumptions.md`    | Last session artifact — runtime verification cowork session |
| `.context/sessions/2026-03-10-cowork-assumptions.jsonl` | Raw JSONL transcript (untracked)                            |
| `verify-assumptions.sh`                                 | Re-runnable runtime assumptions check script                |


---

## Architecture

**Two-tier:**

- **Orchestrator** — long-lived, holds registry, manages sweep state
- **Subagents** — ephemeral per-domain, clean context, communicate via filesystem

**Disk is the shared bus.** `.context/` directories are the IPC layer. Everything is interruptible and resumable by design.

**Viewport:** VS Code workspace-per-domain via `open-kit --cursor`. Workspace file auto-opens context files as tabs, launches Claude Code via `folderOpen` task. Entry point: `code --new-window domain.code-workspace`.

**Context loading:** `hooks/session-start.sh` — SessionStart hook that injects context files deterministically. Written; not yet installed.

**Distillation:** `claude -p` with `--system-prompt-file` — headless, isolated, no shared session history. Disk boundary is the debiasing mechanism.

---

## Key Decisions (highlights — see DECISIONS.md for full rationale)


| Decision                              | Summary                                                                           |
| ------------------------------------- | --------------------------------------------------------------------------------- |
| Disk as shared bus                    | No in-memory subagent comm; interruptibility by design                            |
| Serial sweep                          | Full attention per domain; parallelism reserved for touch --full                  |
| Skills over scripts                   | Claude Code project-local skills as primary implementation                        |
| Staged writes                         | Agents never write directly to MEMORY/DECISIONS; all via distiller                |
| VS Code workspace viewport            | Replaced tmux/neovim — no custom glue needed                                      |
| Claude Code hooks for context loading | Deterministic SessionStart hooks, not LLM-dependent                               |
| Headless `claude -p` for distillation | Clean context isolation; disk boundary = debiasing                                |
| Agent teams NOT used                  | Teams share working dir — wrong primitive for domain isolation                    |
| touch-domain as modal command         | One command: smart default + --full/--new/--no-touchy/-y flags                    |
| Git-aware by default                  | All domains git-tracked; bare repo convention; touch surfaces, not silently fixes |
| Four commands, four concerns          | Clean separation: each command evolves independently                              |
| Domain kit as foundational concept    | VSM-grounded, not just "context engineering"                                      |


---

## Current Status

**SessionStart hook is written.** The last session produced `hooks/session-start.sh` + `hooks/README.md`. Not yet committed or installed. Skill implementation is the active frontier.

**What's been done:**

- All four command specs complete and consistent
- Runtime verified: Claude Code CLI 2.1.72, Cursor CLI, SSH/bare repo on fluffy, workspace folderOpen tasks
- `hooks/session-start.sh` implemented (untracked — needs commit + install)
- `firehose.code-workspace` exists (untracked — needs commit)
- `.cursor/rules/firehose.mdc` created
- `firehose.local.md` updated: Cursor primary, LiteLLM gateway

**What's next (priority order from STATE.md):**

1. Commit `hooks/` and `firehose.code-workspace` to git
2. Install hook: `~/.claude/hooks/session-start.sh` + update `~/.claude/settings.json`
3. Update `touch-domain` skill — modal modes + git precheck
4. Update `touch-full-domain` skill — modal modes
5. Implement `open-kit` skill (`--cursor`, `--terminal`)
6. Write REGISTRY.md (live registry)
7. Write distiller prompt (`distiller-prompt.md`)
8. Design global config format (`~/.firehose/config.md`)
9. End-to-end test: `touch-domain --new` → onboarding → git → workspace → `open-kit --cursor`

---

## Gaps & Warnings

1. **MEMORY.md is stale** — last updated 2026-03-09. Says "No README.md exists" (README is complete), says Alacritty+tmux runtime (now Cursor primary), omits `hooks/`. Distillation needed.
2. `**hooks/` and `firehose.code-workspace` untracked** — two artefacts from the last session need committing.
3. **Hook not installed** — `hooks/session-start.sh` written but not in `~/.claude/hooks/` yet; context loading is still manual.
4. `**sessions/processed/` missing** — no subdirectory for processed session artifacts under `.context/sessions/`.
5. **Skills lag behind spec** — `touch-domain` and `touch-full-domain` don't yet implement modal modes or git precheck.
6. `**open-kit` not implemented** — spec complete, no skill exists yet.
7. **No live REGISTRY.md** — `firehose/REGISTRY.example.md` is a template only.
8. **Distiller prompt not written** — `distiller-prompt.md` doesn't exist; headless distillation can't run yet.
9. `**variety-agent-design.md` lives in `cursus`** — decision pending: copy here or reference externally.

