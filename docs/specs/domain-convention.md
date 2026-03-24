# Domain Convention Spec

> **Partially superseded (2026-03-18, updated 2026-03-19).** The following sections are superseded by newer, more authoritative specs:
>
> | Section | Authoritative spec |
> |---------|-------------------|
> | Directory structure | `file-convention.md` (domain.yaml + persona.md) |
> | domain.yaml / persona.md file roles | `file-convention.md`, `domain-yaml-schema.md` |
> | Git Convention | `set-assembly-spec.md` |
> | Session Entry / Lifecycle | `file-convention.md` (load order), `command-taxonomy.md` |
>
> These sections have been updated to reflect current conventions (domain.yaml, persona.md) but the authoritative specs above should be preferred.
>
> Sections that remain current and authoritative here: Session Files (file types and roles), MEMORY.md and DECISIONS.md structure and semantics.

## Overview

A **domain** is a folder representing a concern — narrow or broad, ephemeral or long-running. Every domain that participates in the orchestration system follows a shared convention for context files, enabling consistent agent bootstrapping, memory accumulation, and session management.

## Directory Structure

```
<domain>/
  .claude/
    domain-toolkit/
      domain.yaml       # Machine-readable manifest, detection signal (tracked)
    ...skills, settings, etc (CC tooling)...
  .context/             # Knowledge layer — gitignored wholesale
    PROFILE.md          # Derived one-pager summary (touch --full output)
    MEMORY.md           # Persistent distilled knowledge across sessions
    DECISIONS.md        # Structured decision log (append-only)
    STATE.md            # Current status snapshot (volatile, frequently updated)
    sessions/
      <timestamp>.md             # Structured session notes
      <timestamp>.draft.md       # Memory draft (agent's proposed memories, written at session close)
      <timestamp>.transcript.md  # Staged transcript (extracted from CC JSONL by stager)
  persona.md            # Agent identity, model tier, context map (tracked)
  README.md             # Canonical description of what this domain is
  ...domain content...
```

## File Roles

### README.md

The canonical, human-maintained description of what this domain *is*. Kept accurate. This is not an agent artifact — it's authored or approved by the human. Lives at the domain root, not inside `.context/`.

### STATE.md

A timely, volatile snapshot of where things stand right now. Updated frequently, possibly every session. Answers: "What's the current status? What's blocked? What's in progress?"

### domain.yaml (`.claude/domain-toolkit/domain.yaml`)

Machine-readable manifest and detection signal. Contains registry metadata: name, type, sets, canonical source, remotes, description. The SessionStart hook checks for this file to detect whether a directory is a managed domain. See `domain-yaml-schema.md` for the full schema.

### persona.md (`<domain>/persona.md`)

Agent identity and context map. Tells a subagent:

- **How to show up**: persona, tone, model tier preference
- **What to read**: pointers to PROFILE.md, MEMORY.md, DECISIONS.md, STATE.md, and any other context files relevant to this domain
- **Behavioral settings**: any domain-specific constraints

Lives at the domain root (tracked in git). Placement is contextual — can also appear in skill directories, subtrees, or globally. See `file-convention.md` for placement rules.

### PROFILE.md

A derived, not authored, one-pager summary of the domain. Produced by `touch-domain --full` by synthesizing README.md, STATE.md, domain.yaml, persona.md, MEMORY.md, DECISIONS.md, and a repo scan. Consumed by the orchestrator for `overview` and by domain entry briefings.

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

Sessions live in `.context/sessions/` and are **permanent**. They are never moved or deleted. The session corpus is the durable asset — re-distillation is always possible.

Session lifecycle tracking, access boundaries, and synthesis markers are defined in `distiller-spec.md`.

### `<timestamp>.md` — Session Notes

Written by the agent during a session. Each entry captures:

- What happened since the last entry
- Decisions made
- Open questions
- Current state of thinking

### `<timestamp>.draft.md` — Memory Draft

The agent's proposed memories for the session, written at session close. This is what the agent *thinks* should be remembered — the subjective view. The distiller uses it as a secondary signal, comparing the agent's judgment against its own objective extraction from session notes.

### `<timestamp>.transcript.md` — Staged Transcript

Session transcript extracted from CC's session JSONL by the stager (`bin/stage-transcripts`). Includes thinking blocks. See `distiller-spec.md` for the staging mechanism, synthesis strategies, and the full session lifecycle.

## Git Convention

Git conventions — remote configuration, custodial checklist, agentic operations, recovery — are defined in `set-assembly-spec.md`. Remote and branch declarations are part of `domain-yaml-schema.md`.

**What belongs in git:**
- All domain content (source, docs, config)
- `.claude/domain-toolkit/domain.yaml` — domain manifest (tracked)
- `persona.md` — agent identity (tracked)

**What doesn't (`.gitignore`):**
- `.context/` — entire knowledge layer (MEMORY.md, DECISIONS.md, STATE.md, PROFILE.md, sessions/)
- `domain.code-workspace` — generated workspace file

## Lifecycle

### Domain Creation (`touch-domain --new`)

1. `touch-domain --new <path>` — path may or may not exist yet
2. If path doesn't exist, create it
3. Interactive onboarding session begins: define what the domain is, its scope, agent persona, initial concerns
4. The onboarding conversation is captured as the first entry in `.context/sessions/`
5. From the session, create: `.claude/domain-toolkit/domain.yaml`, `persona.md`, `.context/` scaffolding, README.md, initial STATE.md, MEMORY.md, DECISIONS.md
6. Initialize git repo per global conventions (bare remote on configured server, initial commit)
7. Run `touch-domain --full` to generate PROFILE.md and `domain.code-workspace`
8. Open the domain viewport: `code --new-window domain.code-workspace`

The domain is born version-controlled, context-aware, and ready for interactive work. The bootstrapping conversation itself is the first session artifact — available to the distiller.

### Session Entry

1. Open domain viewport: `code --new-window domain.code-workspace`
2. Workspace `folderOpen` tasks auto-open context files as tabs and launch Claude Code
3. SessionStart hook detects `.claude/domain-toolkit/domain.yaml`, loads context: persona.md → PROFILE.md → MEMORY.md → DECISIONS.md → STATE.md
4. Agent checks DECISIONS.md revisit conditions
5. Agent checks git status and surfaces concerns (uncommitted changes, unpushed work, remote health)
6. Session begins — agent briefs human on domain state and current concerns

### During Session

1. Work proceeds interactively
2. Agent surfaces files of concern via `code <file>` — they open as tabs in the viewport
3. Session artifacts accumulate in `.context/sessions/`

### Post-Session

1. Stager harvests CC session JSONL into `.context/sessions/` transcripts and CC auto-memory into `.context/`
2. Optionally: distiller (isolated `claude -p` invocation) re-synthesizes MEMORY.md and DECISIONS.md as a second-order pass
3. See `distiller-spec.md` for session tracking, synthesis markers, and the full pipeline

### Periodic Maintenance

- `touch-domain` checks structural health and git status, surfaces concerns
- `touch-domain --full` regenerates PROFILE.md and updates `domain.code-workspace`
- STATE.md updated to reflect current status
- DECISIONS.md revisit conditions checked by agents on entry
- Git housekeeping: ensure bare remote exists, no orphaned branches, no long-lived uncommitted work
