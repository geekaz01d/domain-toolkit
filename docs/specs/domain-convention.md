# Domain Convention Spec

> **Partially superseded (2026-03-18).** The following sections of this document have been replaced by newer specs:
>
> | Section | Superseded by |
> |---------|---------------|
> | Directory structure (agent.md) | `file-convention.md` (domain.yaml + persona.md) |
> | agent.md file role | `file-convention.md`, `domain-yaml-schema.md` |
> | Git Convention | `git-operations.md` |
> | Session Entry / Lifecycle | `file-convention.md` (load order), `command-taxonomy.md` |
>
> Sections that remain current: Session Files (lifecycle, access boundaries, frontmatter convention), MEMORY.md and DECISIONS.md structure and semantics.

## Overview

A **domain** is a folder representing a concern — narrow or broad, ephemeral or long-running. Every domain that participates in the orchestration system follows a shared convention for context files, enabling consistent agent bootstrapping, memory accumulation, and session management.

## Directory Structure

```
<domain>/
  .claude/
    agent.md            # Agent config: persona, model tier, context map (tracked)
    ...skills, settings, etc (CC tooling)...
  .context/             # Knowledge layer — gitignored wholesale
    PROFILE.md          # Derived one-pager summary (touch --full output)
    MEMORY.md           # Persistent distilled knowledge across sessions
    DECISIONS.md        # Structured decision log (append-only)
    STATE.md            # Current status snapshot (volatile, frequently updated)
    sessions/
      <timestamp>.md        # Structured session notes (frontmatter-tracked lifecycle)
      <timestamp>.draft.md  # Memory draft (agent's proposed memories, written at session close)
      <timestamp>.log       # Raw session transcript (optional)
  README.md             # Canonical description of what this domain is
  ...domain content...
```

## File Roles

### README.md

The canonical, human-maintained description of what this domain *is*. Kept accurate. This is not an agent artifact — it's authored or approved by the human. Lives at the domain root, not inside `.context/`.

### STATE.md

A timely, volatile snapshot of where things stand right now. Updated frequently, possibly every session. Answers: "What's the current status? What's blocked? What's in progress?"

### agent.md (`.claude/agent.md`)

Agent configuration and context map. Tells a subagent:

- **How to show up**: persona, tone, model tier preference
- **What to read**: pointers to MEMORY.md, DECISIONS.md, and any other context files relevant to this domain
- **Behavioral settings**: distillation strategy (`memory_review: auto | flag | manual`), any domain-specific constraints

This is the **start file** — the first thing an agent reads when entering a domain. Lives at `.claude/agent.md` (tracked in git, not in `.context/`). Doubles as the domain identity signal — the SessionStart hook checks for `.claude/agent.md` to detect whether a directory is a managed domain.

### PROFILE.md

A derived, not authored, one-pager summary of the domain. Produced by `touch --full` by synthesizing README.md, STATE.md, agent.md, MEMORY.md, DECISIONS.md, and a repo scan. Consumed by the orchestrator for `/map` display and by `/sweep` for opening briefings.

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

Sessions live in `.context/sessions/` and are **permanent**. They are never moved or deleted. Their lifecycle is tracked via YAML frontmatter.

### Session Lifecycle

```yaml
---
status: active         # session in progress
created: 2026-03-10T14:37:22
---
```

| Status | Meaning | Set by |
|--------|---------|--------|
| `active` | Session is in progress. | Agent (on session start) |
| `closed` | Session is complete. Ready for distillation. | Agent (opportunistically at session end) |
| `distilled` | Distiller has processed this session. | Distiller (after successful run) |

The agent may **opportunistically close** a session when it senses work is winding down. If the session continues, the agent resets status to `active`. This is cheap — just a frontmatter edit.

Because session files are permanent, re-distillation is always possible. Reset a session's status to `closed` and the distiller will reprocess it. The session corpus is the durable asset.

### Access Boundaries

| Actor | Session files | Canonical files |
|-------|--------------|-----------------|
| **Working agent** | Writes (append-only). Never reads back. | Reads on entry. Never writes. |
| **Distiller** | Reads (to extract knowledge). Never writes (except frontmatter status). | Writes (proposed or committed updates). |
| **Human** | Can author directly. | Approves distiller proposals. Can edit directly. |

### `<timestamp>.md` — Session Notes

Written by the agent during a session. Each entry captures:

- What happened since the last entry
- Decisions made
- Open questions
- Current state of thinking

### `<timestamp>.draft.md` — Memory Draft

The agent's proposed memories for the session, written at session close. This is what the agent *thinks* should be remembered — the subjective view. The distiller uses it as a secondary signal, comparing the agent's judgment against its own objective extraction from session notes.

### `<timestamp>.log` — Raw Transcript

Full session transcript including thinking blocks. Capture mechanism TBD — Claude Code does not natively export transcripts. Candidates: LiteLLM gateway logging, `script` terminal capture, future Claude Code export feature. This is a major open design question (see Open Threads).

When available, raw transcripts are valuable input for the `careful` and `adversarial` distillation strategies, and essential for corpus re-derivation when the distiller improves.

## Git Convention

Domains that are git repos follow a standard remote and repository configuration. This provides an audit trail for agentic changes and ensures work is never lost.

**Standard setup:**
- Local git repo in the domain directory
- Bare remote on a configured primary server (host and path pattern defined in local config)
- Optional secondary mirror (e.g., GitHub private repo, per-domain opt-in)

**Global defaults** are defined in a system-wide domain-toolkit config (e.g., `~/.claude/domain-toolkit/config.md`). Environment-specific settings (server hostname, paths) live in `.context/domain-toolkit.local.md`. Per-domain overrides live in `agent.md`.

**What belongs in git:**
- All domain content (source, docs, config)
- `.claude/agent.md` — domain configuration (tracked)

**What doesn't (`.gitignore`):**
- `.context/` — entire knowledge layer (MEMORY.md, DECISIONS.md, STATE.md, PROFILE.md, sessions/)
- `domain.code-workspace` — generated workspace file
- `.context/*.local.md` — environment-specific config (if not ignoring `.context/` wholesale)

## Lifecycle

### Domain Creation (`touch-domain --new`)

1. `touch-domain --new <path>` — path may or may not exist yet
2. If path doesn't exist, create it
3. Interactive onboarding session begins: define what the domain is, its scope, agent persona, initial concerns
4. The onboarding conversation is captured as the first entry in `.context/sessions/`
5. From the session, create: `.claude/agent.md`, `.context/` scaffolding, README.md, initial STATE.md, MEMORY.md, DECISIONS.md
6. Initialize git repo per global conventions (bare remote on configured server, initial commit)
7. Run `touch-domain --full` to generate PROFILE.md and `domain.code-workspace`
8. Open the domain viewport: `code --new-window domain.code-workspace`

The domain is born version-controlled, context-aware, and ready for interactive work. The bootstrapping conversation itself is the first session artifact — available to the distiller.

### Session Entry

1. Open domain viewport: `code --new-window domain.code-workspace`
2. Workspace `folderOpen` tasks auto-open context files as tabs and launch Claude Code
3. SessionStart hook detects `.claude/agent.md`, loads context: agent.md → PROFILE.md → MEMORY.md → DECISIONS.md → STATE.md
4. Agent checks DECISIONS.md revisit conditions
5. Agent checks git status and surfaces concerns (uncommitted changes, unpushed work, remote health)
6. Session begins — agent briefs human on domain state and current concerns

### During Session

1. Work proceeds interactively
2. Agent surfaces files of concern via `code <file>` — they open as tabs in the viewport
3. Session artifacts accumulate in `.context/sessions/`

### Post-Session

1. Scheduled cron job (or manual `distill <domain>`) detects sessions with `status: closed`
2. Distiller (isolated `claude -p` invocation) reads closed sessions + current canonical files
3. Updated canonical files written with `status: proposed` frontmatter (in `manual` mode)
4. Review gate (per agent.md config): human review, auto-commit, or flag
5. Human approves by updating frontmatter (or distiller auto-commits in `auto` mode)
6. Distiller marks processed sessions as `status: distilled` in their frontmatter
7. Git commit captures the session's canonical changes

### Periodic Maintenance

- `touch-domain` checks structural health and git status, surfaces concerns
- `touch-domain --full` regenerates PROFILE.md and updates `domain.code-workspace`
- STATE.md updated to reflect current status
- DECISIONS.md revisit conditions checked by agents on entry
- Git housekeeping: ensure bare remote exists, no orphaned branches, no long-lived uncommitted work
