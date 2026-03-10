# Domain Convention Spec

## Overview

A **domain** is a folder representing a concern — narrow or broad, ephemeral or long-running. Every domain that participates in the orchestration system follows a shared convention for context files, enabling consistent agent bootstrapping, memory accumulation, and session management.

## Directory Structure

```
<domain>/
  .context/
    PROFILE.md          # Derived one-pager summary (touch --full output)
    MEMORY.md           # Persistent distilled knowledge across sessions
    DECISIONS.md        # Structured decision log (append-only)
    agent.md            # Agent config: persona, model tier, context map
    STATE.md            # Current status snapshot (volatile, frequently updated)
    sessions/
      <timestamp>.md        # Structured session notes (agent-written checkpoints)
      <timestamp>.log       # Raw session transcript (Claude Code native persistence or optional claudeProcessWrapper)
      <timestamp>.draft.md  # Memory draft (agent's proposed memories, pre-distillation)
      processed/            # Completed sessions (moved here after distillation)
  README.md             # Canonical description of what this domain is
  ...domain content...
```

## File Roles

### README.md

The canonical, human-maintained description of what this domain *is*. Kept accurate. This is not an agent artifact — it's authored or approved by the human. Lives at the domain root, not inside `.context/`.

### STATE.md

A timely, volatile snapshot of where things stand right now. Updated frequently, possibly every session. Answers: "What's the current status? What's blocked? What's in progress?"

### agent.md

Agent configuration and context map. Tells a subagent:

- **How to show up**: persona, tone, model tier preference
- **What to read**: pointers to MEMORY.md, DECISIONS.md, and any other context files relevant to this domain
- **Behavioral settings**: distillation strategy (`memory_review: auto | flag | manual`), checkpoint conventions, any domain-specific constraints

This is the **start file** — the first thing an agent reads when entering a domain.

### PROFILE.md

A derived, not authored, one-pager summary of the domain. Produced by `touch --full` by synthesizing README.md, STATE.md, agent.md, MEMORY.md, DECISIONS.md, and a repo scan. Consumed by the orchestrator for `/map` display and by `/firehose` for opening briefings.

PROFILE.md is **regenerated, not edited**. If the profile is wrong, fix the source files and re-run `touch --full`.

### MEMORY.md

Persistent knowledge distilled from past sessions. Not a session log — a refinement. Contains accumulated understanding, learned preferences, key context, and open threads that carry forward.

Structure:

```markdown
## Domain Understanding
[What this domain is about, refined over time]

## Key Context
[Facts, constraints, preferences learned across sessions]

## Open Threads
[Things started but not resolved — carry forward]

## Last Updated: <date>
```

MEMORY.md is updated by the **distillation pipeline**, not by the agent directly during a session. Agents write to session files and memory drafts; the distiller merges approved material into MEMORY.md.

### DECISIONS.md

Structured, append-only decision log. Each entry follows a consistent format:

```markdown
## <date>: <decision title>
- **Context**: Why this decision came up
- **Alternatives considered**: What else was on the table
- **Deciding factors**: Why this option won
- **Revisit if**: Conditions under which this decision should be reconsidered
```

The "revisit if" field is a live tripwire — agents entering the domain should check these conditions and flag when they appear to be met.

DECISIONS.md is append-only. The distiller may add new entries but never modifies or removes existing ones.

## Session Files

Sessions live in `.context/sessions/` and serve as the raw material for distillation.

### `<timestamp>.md` — Structured Session Notes

Written by the agent at checkpoints during a session. Each checkpoint captures:

- What happened since last checkpoint
- Decisions made
- Open questions
- Current state of thinking

Checkpoints are triggered by `/checkpoint` command (human-initiated) or suggested by the agent and confirmed by the human. The agent never checkpoints without human consent.

### `<timestamp>.log` — Raw Transcript

Captured via Claude Code's native session persistence or the `claudeProcessWrapper` setting (not the agent). Exists as a backup and audit trail. Not the primary input for distillation — checkpoints are.

### `<timestamp>.draft.md` — Memory Draft

The agent's proposed memories for the session, written at session close (`/checkpoint --close`). This is what the agent *thinks* should be remembered. It is staged, not canonical — the distiller processes it against existing MEMORY.md and produces a proposed merge.

### `processed/`

After distillation, session files are moved here. The presence of unprocessed files in `sessions/` indicates pending distillation work — the sessions directory is an **inbox**.

## Git Convention

Domains that are git repos follow a standard remote and repository configuration. This provides an audit trail for agentic changes and ensures work is never lost.

**Standard setup:**
- Local git repo in the domain directory
- Bare remote on a configured primary server (host and path pattern defined in local config)
- Optional secondary mirror (e.g., GitHub private repo, per-domain opt-in)

**Global defaults** are defined in a system-wide firehose config (e.g., `~/.firehose/config.md`). Environment-specific settings (server hostname, paths) live in `firehose.local.md`. Per-domain overrides live in `agent.md`.

**What belongs in git:**
- All domain content (source, docs, config)
- `.context/` canonical files (MEMORY.md, DECISIONS.md, STATE.md, agent.md)
- `.context/sessions/` (session artifacts are part of the audit trail)
- `domain.code-workspace`

**What doesn't:**
- `.context/PROFILE.md` — derived, regenerated by touch (add to `.gitignore`)
- `.proposed` files — transient distiller output (add to `.gitignore`)

## Lifecycle

### Domain Creation (`touch-domain --new`)

1. `touch-domain --new <path>` — path may or may not exist yet
2. If path doesn't exist, create it
3. Interactive onboarding session begins: define what the domain is, its scope, agent persona, initial concerns
4. The onboarding conversation is captured as the first entry in `.context/sessions/`
5. From the session, create: `.context/` scaffolding, README.md, agent.md, initial STATE.md, MEMORY.md, DECISIONS.md
6. Initialize git repo per global conventions (bare remote on configured server, initial commit)
7. Run `touch-domain --full` to generate PROFILE.md and `domain.code-workspace`
8. Open the domain viewport: `code --new-window domain.code-workspace`

The domain is born version-controlled, context-aware, and ready for interactive work. The bootstrapping conversation itself is the first session artifact — available to the distiller.

### Session Entry

1. Open domain viewport: `code --new-window domain.code-workspace`
2. Workspace `folderOpen` tasks auto-open context files as tabs and launch Claude Code
3. SessionStart hook loads context: agent.md → PROFILE.md → MEMORY.md → DECISIONS.md → STATE.md
4. Agent checks DECISIONS.md revisit conditions
5. Agent checks git status and surfaces concerns (uncommitted changes, unpushed work, remote health)
6. Session begins — agent briefs human on domain state and current concerns

### During Session

1. Work proceeds interactively
2. Agent surfaces files of concern via `code <file>` — they open as tabs in the viewport
3. `/checkpoint` writes structured notes to session file
4. Agent may suggest checkpoints; human confirms
5. `/checkpoint --close` signals session end, triggers memory draft

### Post-Session

1. Distiller (isolated `claude -p` invocation) processes session checkpoints + memory draft against canonical files
2. Proposed updates to MEMORY.md and DECISIONS.md are generated
3. Review gate (per agent.md config): human review, auto-commit, or flag
4. Approved updates merge into canonical files
5. Session files move to `processed/`
6. Git commit captures the session's canonical changes

### Periodic Maintenance

- `touch-domain` checks structural health and git status, surfaces concerns
- `touch-domain --full` regenerates PROFILE.md and updates `domain.code-workspace`
- STATE.md updated to reflect current status
- DECISIONS.md revisit conditions checked by agents on entry
- Git housekeeping: ensure bare remote exists, no orphaned branches, no long-lived uncommitted work
