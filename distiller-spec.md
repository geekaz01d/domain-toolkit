# Distiller Spec

## Overview

The distiller is a standalone process that transforms session artifacts into canonical domain knowledge. It runs **outside** of interactive sessions — post-session, batched, on-demand, or scheduled. It is not coupled to the agent or the orchestrator; it operates on the filesystem convention.

The distiller's core principle: **agents never write directly to canonical files**. All agent output is staged. The distiller is the commit gate.

## Interface Contract

**Input:**
- Unprocessed session files from `.context/sessions/` (checkpoints, memory drafts)
- Current canonical state: `MEMORY.md`, `DECISIONS.md`
- Domain context: `README.md`, `STATE.md` (for grounding)

**Output:**
- Proposed updates to `MEMORY.md` (as `MEMORY.md.proposed` or inline diff)
- Proposed new entries for `DECISIONS.md` (as `DECISIONS.md.proposed` or inline diff)
- Conflict report (if proposed changes contradict existing canonical material)
- Optionally: updated `STATE.md` if session outcomes affect current status

**Side effects:**
- Processed session files moved to `.context/sessions/processed/`

## Trigger Modes

The distiller can be invoked in any of these ways:

| Mode | Trigger | Use Case |
|------|---------|----------|
| Post-session hook | Claude Code `Stop` hook or post-session script | Immediate distillation after a session |
| Manual | `distill <domain>` or `/distill-domain` skill | On-demand, human-initiated |
| Batch | `distill --all` | Process all domains with pending session files |
| Scheduled | cron or similar | Nightly batch run across all domains |
| Inline | `/distill-domain` from within a session | Mid-session distillation (rare, but available) |

## Review Gate

The distiller produces proposed changes, not committed changes. The review gate determines what happens next:

| Mode | Behavior | Configured In |
|------|----------|---------------|
| `manual` | Proposed files written; human reviews and approves | agent.md |
| `flag` | Auto-commits non-conflicting changes; flags conflicts for human review | agent.md |
| `auto` | Auto-commits all changes | agent.md |

Default is `manual`. Per-domain override via `memory_review` setting in agent.md.

For `manual` and `flag` modes, the distiller writes `.proposed` files:
```
.context/
  MEMORY.md
  MEMORY.md.proposed      # distiller output — review this
  DECISIONS.md
  DECISIONS.md.proposed   # distiller output — review this
```

Approval is an explicit action (TBD: could be `distill --approve <domain>`, or manual file replacement, or a diff-and-merge workflow).

## Distillation Strategies

The distiller's internal processing is a **black box with a pluggable strategy**. The interface contract stays the same regardless of strategy. Strategies are specified in agent.md or as CLI arguments.

### Simple (default)

Single model call. Prompt includes session checkpoints, existing canonical files, and instructions to produce structured updates.

- Model: configurable, default Haiku-tier (distillation is summarization, not deep reasoning)
- Fast, cheap, good for routine sessions

### Careful

Single model call with a higher-tier model (Sonnet or Opus).

- Used for domains with high-stakes decisions or complex context
- More expensive but better at nuance, conflict detection, and judgment calls

### Adversarial

Multi-model or multi-pass review.

- Pass 1: generate proposed updates (any model)
- Pass 2: adversarial review — a second model (or same model, different prompt) evaluates the proposals against existing canonical state, checks for conflicts, omissions, mischaracterizations
- Pass 3 (optional): reconciliation if the reviewer flagged issues

More expensive, higher quality. Appropriate for domains where memory accuracy is critical.

### Custom

User-defined strategy. The distiller accepts a strategy script or prompt template, enabling arbitrary processing pipelines.

## Prompt Structure

The distiller prompt (for the simple strategy) follows this general shape:

```
You are a distillation agent. Your job is to process session artifacts
and produce proposed updates to canonical domain files.

## Existing Canonical State

### MEMORY.md
<contents of current MEMORY.md>

### DECISIONS.md
<contents of current DECISIONS.md>

## Session Artifacts

### Checkpoints
<contents of session checkpoint files>

### Memory Draft (agent's proposed memories)
<contents of .draft.md if present>

## Instructions

1. Identify new knowledge, context, or preferences that should persist in MEMORY.md
2. Identify any decisions made, with rationale and revisit conditions, for DECISIONS.md
3. Flag any conflicts between session material and existing canonical state
4. Preserve the existing structure of MEMORY.md sections
5. DECISIONS.md entries are append-only — never modify existing entries
6. If a previous decision's revisit conditions appear to be met, flag this explicitly

## Output Format

Produce two sections:

### MEMORY.md Updates
[Updated MEMORY.md content, preserving existing structure with new material merged in]

### DECISIONS.md Updates
[New entries only, in the standard format]

### Conflicts
[Any contradictions between session material and existing canonical state]
```

## Conflict Handling

Conflicts arise when session material contradicts existing canonical state. Examples:

- Agent concluded X, but MEMORY.md records Y from a prior session
- A new decision contradicts or supersedes a previous decision
- Session material suggests a revisit condition has been met

The distiller surfaces conflicts explicitly. It does not silently resolve them. In `manual` mode, conflicts are presented to the human. In `flag` mode, conflicts block auto-commit for affected entries. In `auto` mode, conflicts are logged but the most recent session material wins (last-write-wins).

## Session Artifact Processing

### What the distiller reads

1. **Checkpoint files** (`<timestamp>.md`): Primary input. Structured, pre-curated signal. These are the main source of material for distillation.

2. **Memory drafts** (`<timestamp>.draft.md`): The agent's own assessment of what should be remembered. Used as a secondary signal — the distiller compares the agent's judgment against its own extraction from checkpoints.

3. **Raw logs** (`<timestamp>.log`): Not read by default. Available as fallback if checkpoints are incomplete or if the `careful` or `adversarial` strategy wants to cross-reference.

### Processing order

1. Read existing canonical state (MEMORY.md, DECISIONS.md)
2. Read all unprocessed session files, chronologically
3. Run the selected strategy
4. Write proposed updates
5. Mark session files as processed (move to `processed/`)

### Human-authored session notes

The distiller does not care who authored session artifacts. If a human drops a markdown file into `.context/sessions/`, it gets processed the same way. The filesystem is the interface — not the chat.

## CLI Interface

```
distill <domain>                  # distill a single domain
distill --all                     # distill all domains with pending sessions
distill <domain> --strategy careful  # override strategy for this run
distill <domain> --model opus     # override model for this run
distill <domain> --approve        # approve pending .proposed files
distill <domain> --diff           # show diff between current and proposed
distill <domain> --dry-run        # show what would be processed, don't execute
distill --pending                 # list all domains with unprocessed sessions
```

## Implementation Notes

### Isolation Requirement

The distiller **must** run in isolated context — a separate Claude Code invocation with no access to the working session's conversation history. This is a debiasing mechanism, not an implementation convenience. The working agent carries completion bias and sunk-cost reasoning from its session. The distiller reads cold artifacts off disk and evaluates them without attachment to outcomes.

Invocation:

```bash
claude -p --system-prompt-file distiller-prompt.md \
       "Distill domain at /path/to/domain"
```

Print mode (`-p`), fresh session, no shared context. The distiller reads `.context/sessions/` and `.context/MEMORY.md` / `DECISIONS.md` from disk.

### Phase 1 — Minimal

- Headless `claude -p` with distillation system prompt
- Writes `.proposed` files
- Human reviews via VS Code diff view or editor
- Manual file replacement to approve

### Phase 2 — Automation

- Claude Code `Stop` hook or post-session script triggers distillation automatically
- `--approve` command for streamlined approval
- Batch mode across all domains via sweep script
- Strategy selection from agent.md config

### Phase 3 — Advanced

- Adversarial strategy implementation
- Conflict resolution via VS Code diff/merge tooling
- Distillation quality metrics (how often does the human reject proposals?)
- Incremental distillation (process checkpoints as they arrive, not just at session end)

## Design Principles

1. **Staged, not direct.** Agents never write to canonical files. All writes are proposals.
2. **Standalone.** The distiller is not part of the agent or the orchestrator. It's a separate tool that reads and writes to the filesystem.
3. **Strategy is configuration.** The interface contract doesn't change when you swap strategies. Simple, careful, adversarial, custom — same inputs, same outputs.
4. **Human-compatible.** The filesystem is the interface. Humans can author session notes, review proposed diffs, and approve changes using their own tools.
5. **Conservative with decisions.** DECISIONS.md is append-only. The distiller adds but never removes or modifies. Revisit conditions are flagged, not acted upon.
