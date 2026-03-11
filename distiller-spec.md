# Distiller Spec

## Overview

The distiller is a standalone process that transforms session artifacts into canonical domain knowledge. It runs **outside** of interactive sessions — scheduled, batched, or on-demand. It is not coupled to the agent or the orchestrator; it operates on the filesystem convention.

The distiller's core principle: **agents never write directly to canonical files**. The distiller is the commit gate. Canonical files (`MEMORY.md`, `DECISIONS.md`) are the distiller's output, not the agent's.

## Access Boundaries

The system enforces clean separation between who reads and writes what:

| Actor | Session transcripts | Checkpoints | Canonical files | CC session JSONL |
|-------|-------------------|-------------|-----------------|------------------|
| **Working agent** | Never reads or writes. | Writes (append-only via `/checkpoint`). | Reads on entry. Never writes. | Written by CC runtime. Agent unaware. |
| **Stager** (`stage-transcripts`) | Writes (extracts from JSONL). | Never touches. | Never touches. | Reads (source of truth). |
| **Distiller** | Reads (primary input). | Reads (attention markers). | Writes (proposed or committed updates). | Appends `[FIREHOSE]` marker on completion. |
| **Human** | Can author directly (drop a .md into sessions/). | Can author directly. | Approves distiller proposals. Can edit directly. | Sees marker if resuming a distilled session. |

The agent's job during a session is twofold: do the work, and optionally lay down checkpoints at important moments. The **transcript** (extracted from CC's native session JSONL) is the primary record — it captures everything including thinking blocks. Checkpoints are the human or agent saying "this moment matters" — attention markers, not the primary source.

## Session Lifecycle

### Source of truth

Claude Code writes a JSONL file per session at `~/.claude/projects/<encoded-project-path>/<session-id>.jsonl`. This file contains everything: user messages, assistant messages (with thinking blocks), tool calls and results. It is written continuously by CC — every turn appends.

The **stager** (`bin/stage-transcripts`) extracts these JSONL files into readable `.transcript.md` files in `.context/sessions/`. The staged transcript is a derived artifact — the JSONL is the source of truth.

### Tracking state

Session state is tracked in `.context/sessions/.staged-sessions`, a TSV file:

```
<session_id>\t<jsonl_byte_size>
```

The stager updates this on every run. If the JSONL has grown (session was continued), the stager re-extracts and overwrites the transcript atomically.

### Distillation marker

When the distiller finishes processing a session, it appends a **`[FIREHOSE]` marker** directly to the CC session JSONL — a user-type message that serves three purposes:

1. **Human sees it** when browsing or resuming the session in CC
2. **Agent sees it** if the session is continued — knows prior content has been captured
3. **Distiller sees it** on subsequent runs — the marker is the high-water mark

The marker format:

```
[FIREHOSE] ───────────────────────────────────────────
⚑ Session distilled at <timestamp>

Content above this line has been processed into
MEMORY.md and DECISIONS.md for this domain.

If you continue this session, new content will need
to be distilled separately.
──────────────────────────────────────────────────────
```

This is appended as a regular user message (`isMeta: false`) so it renders visibly in CC's conversation view.

### Continued sessions

If a session is continued after distillation:

1. New content lands in the JSONL after the `[FIREHOSE]` marker
2. The stager detects the JSONL has grown (size > recorded size) and re-extracts the full transcript
3. The distiller, on its next run, sees the marker and knows to process only content after it

### Re-distillation

The session JSONL corpus is the durable asset. To re-distill:

- Remove the `[FIREHOSE]` marker from the JSONL (or the stager entry from `.staged-sessions`)
- The distiller will reprocess the full session

Useful when the distiller prompt has improved, a better model is available, or canonical files were corrupted.

### Checkpoints

Checkpoints (`/checkpoint`) are **attention markers**, not the primary source material. They signal "this moment matters" — laid down by either the human or the agent during a session. The distiller pays extra attention to checkpointed moments but does not depend on checkpoints existing. A session with no checkpoints is still fully distillable from the transcript alone.

`/checkpoint --close` remains a human signal that the session is done — useful for triggering immediate distillation rather than waiting for the cron job to detect a stable session.

## Interface Contract

**Input:**
- Session transcripts from `.context/sessions/*.transcript.md` (primary source — includes thinking blocks)
- Checkpoint files from `.context/sessions/*.md` (attention markers — optional)
- Current canonical state: `MEMORY.md`, `DECISIONS.md`
- Domain context: `README.md`, `STATE.md` (for grounding)

**Output:**
- Updated `MEMORY.md` (with frontmatter indicating `status: proposed` or committed directly, per review mode)
- Updated `DECISIONS.md` (same frontmatter convention)
- Conflict report in `DISTILL-CONFLICTS.md` (if proposed changes contradict existing canonical material)

**Side effects:**
- `[FIREHOSE]` marker appended to the CC session JSONL (high-water mark)
- `.staged-sessions` updated to reflect processed state

## Trigger Modes

| Mode | Trigger | Execution Context |
|------|---------|-------------------|
| **Scheduled** | Cron job detects staged transcripts without `[FIREHOSE]` markers | System-level. No interactive session. Primary path. |
| **Manual** | `distill <domain>` or `/distill-domain` skill | From any terminal or session. Human-initiated. |
| **Batch** | `distill --all` | Iterates registry. Processes all domains with pending work. |
| **Explicit close** | `/checkpoint --close` during a session | Human signal that session is done — triggers immediate distillation. |

The **scheduled cron job** is the primary trigger. It walks the domain registry, checks each domain's `.context/sessions/` for transcripts that haven't been fully distilled (by scanning the source JSONLs for `[FIREHOSE]` markers), and runs distillation against those domains. This decouples distillation from the working session entirely.

The signal is: **staged transcripts exist whose source JSONLs have content after (or without) a `[FIREHOSE]` marker**.

## Review Gate

The distiller uses frontmatter on canonical files to stage proposals:

```yaml
---
status: proposed
distilled_at: 2026-03-10T18:30:00
source_sessions:
  - 2026-03-10T14-37-22
  - 2026-03-10T16-52-00
---
```

The review mode (from `agent.md`) determines what happens:

| Mode | Behavior | Configured In |
|------|----------|---------------|
| `manual` | Canonical files written with `status: proposed`. Human reviews and approves (removes/updates frontmatter). | agent.md |
| `flag` | Non-conflicting changes committed directly. Conflicts written as `status: proposed`. | agent.md |
| `auto` | All changes committed directly. Conflicts logged but resolved last-write-wins. | agent.md |

Default is `manual`. Per-domain override via `memory_review` setting in agent.md.

Approval is flipping `status: proposed` to `status: approved` (or removing the frontmatter entirely). The human can also edit the content during review.

## Three Perspectives

Three distinct viewpoints produce knowledge about a session:

- **Human** (subjective): steers the session, makes decisions, lays down checkpoints at moments they consider important. Carries intent and priorities the agent may not fully grasp.
- **Working agent** (subjective): writes checkpoint summaries and memory drafts, reasons through problems in thinking blocks. Carries the in-session perspective — attached to outcomes, influenced by recency and sunk cost.
- **Distiller** (objective): reads the full session transcript off disk post-session. Has access to everything — the human's words, the agent's thinking blocks, the tool calls, the checkpoints. Evaluates without attachment.

The distiller's job is to **form its own view first**, then weigh it against the human and agent perspectives. Assume both the human and the agent may have lost the plot. The distiller should cut through noise to see things plainly, then consider this on balance with the human and agent's perspectives. The best truth should end up in `MEMORY.md` and `DECISIONS.md`.

### How the distiller weighs perspectives

1. **Read the full transcript** — including thinking blocks. Understand what was explored, what was tried, what worked, what didn't.
2. **Form an independent view** — what are the real decisions, insights, and learnings from this session? What matters for future sessions?
3. **Read any checkpoints** — these are attention markers from the human and agent. They signal "this moment matters."
4. **Compare all three views:**
   - **Agreement across all three**: high confidence. Commit.
   - **Distiller sees something others missed**: likely real — the participants may have been too close to notice. Include it.
   - **Human or agent flagged something the distiller doesn't extract**: important signal — they had live context (tone, reactions, subtext). Surface this rather than silently dropping their view.
   - **Direct contradiction**: flag for human review. The distiller's job is to surface the disagreement clearly, not to be the tiebreaker.

## Distillation Strategies

The distiller's internal processing is a **black box with a pluggable strategy**. The interface contract stays the same regardless of strategy. Strategies are specified in agent.md or as CLI arguments.

### Simple (default)

Single model call. Prompt includes session transcript, any checkpoints, existing canonical files, and instructions to produce structured updates.

- Model: configurable, default **Opus-tier** — distillation is judgment-heavy, not mere summarization. The distiller must independently assess reasoning quality, spot where the human or agent lost the plot, and extract the best truth.
- Can be downgraded to Sonnet for routine/low-stakes domains once a proven prompt exists

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
You are a distillation agent. Your job is to read a full session transcript —
including the agent's thinking blocks — and extract the important reasoning,
decisions, and knowledge into canonical domain files.

You are objective. The human and the agent may have lost the plot during
the session. Your job is to cut through noise and see things plainly,
then weigh your assessment against theirs.

## Existing Canonical State

### MEMORY.md
<contents of current MEMORY.md>

### DECISIONS.md
<contents of current DECISIONS.md>

## Session Transcript

<full transcript including thinking blocks, tool calls, and conversation>

## Checkpoints (attention markers)

<any checkpoint files from this session — these are moments the human
or agent flagged as important. Pay extra attention here, but do not
depend on them exclusively.>

## Instructions

1. Read the full transcript. Understand what was explored, what was
   tried, what worked, what didn't. Pay attention to thinking blocks —
   they reveal the agent's actual reasoning, not just its output.
2. Form your own independent view: what are the real decisions, insights,
   and learnings? What matters for future sessions in this domain?
3. Compare your view against any checkpoints and memory drafts the agent
   produced. Note agreement and disagreement.
4. Identify new knowledge for MEMORY.md — things that should persist
5. Identify decisions for DECISIONS.md — with rationale and revisit conditions
6. Flag any conflicts between session material and existing canonical state
7. Preserve the existing structure of MEMORY.md sections
8. DECISIONS.md entries are append-only — never modify existing entries
9. If a previous decision's revisit conditions appear to be met, flag explicitly

## Output Format

Produce three sections:

### MEMORY.md Updates
[Updated MEMORY.md content, preserving existing structure with new material merged in]

### DECISIONS.md Updates
[New entries only, in the standard format]

### Conflicts
[Any contradictions between session material and existing canonical state,
including cases where your assessment disagrees with the human or agent's]
```

## Conflict Handling

Conflicts arise when session material contradicts existing canonical state. Examples:

- Agent concluded X, but MEMORY.md records Y from a prior session
- A new decision contradicts or supersedes a previous decision
- Session material suggests a revisit condition has been met

The distiller surfaces conflicts explicitly in `DISTILL-CONFLICTS.md`. It does not silently resolve them. In `manual` mode, conflicts are presented to the human. In `flag` mode, conflicts block auto-commit for affected entries. In `auto` mode, conflicts are logged but the most recent session material wins (last-write-wins).

## Session Artifact Processing

### What the distiller reads

1. **Session transcripts** (`<timestamp>.transcript.md`): Primary input. The full session record extracted from CC's JSONL, including user messages, assistant messages, thinking blocks, and tool call summaries.

2. **Checkpoint files** (`<timestamp>.md`): Attention markers. Moments the human or agent flagged as important during the session. The distiller pays extra attention here but does not depend on checkpoints existing.

3. **Memory drafts** (embedded in checkpoint files): The agent's own assessment of what should be remembered. A secondary signal for comparison.

### Processing order

1. Read existing canonical state (MEMORY.md, DECISIONS.md)
2. Read session transcripts, chronologically
3. Read any checkpoint files for attention markers
4. Run the selected strategy
5. Write updated canonical files (with appropriate frontmatter per review mode)
6. Append `[FIREHOSE]` distillation marker to the CC session JSONL
7. Write `DISTILL-CONFLICTS.md` if conflicts were detected

### Human-authored session notes

The distiller does not care who authored session artifacts. If a human drops a markdown file into `.context/sessions/`, it gets processed alongside transcripts. The filesystem is the interface — not the chat.

## CLI Interface

```
distill <domain>                     # distill a single domain (closed sessions)
distill --all                        # distill all domains with closed sessions
distill <domain> --strategy careful  # override strategy for this run
distill <domain> --model opus        # override model for this run
distill <domain> --re-distill        # reset distilled sessions to closed, re-run
distill <domain> --dry-run           # show what would be processed, don't execute
distill --pending                    # list all domains with closed (undistilled) sessions
```

## Implementation Notes

### Isolation Requirement

The distiller **must** run in isolated context — a separate Claude Code invocation with no access to the working session's conversation history. This is a debiasing mechanism, not an implementation convenience. The working agent carries completion bias and sunk-cost reasoning from its session. The distiller reads cold artifacts off disk and evaluates them without attachment to outcomes.

Invocation:

```bash
cd /path/to/domain && claude -p \
  --system-prompt-file ~/sources/firehose/distiller-prompt.md \
  "Distill this domain"
```

Print mode (`-p`), fresh session, no shared context. The distiller reads `.context/sessions/` and `.context/MEMORY.md` / `DECISIONS.md` from disk. Running from the domain root avoids cross-project permission issues.

### Transcript Staging (cron)

A cron job (`bin/stage-transcripts`) runs periodically and:

1. Reads the domain registry (`firehose/REGISTRY.md`)
2. For each domain, reads `.context/sessions/session-index.jsonl`
3. For each session, checks if the source JSONL has grown since last staging
4. Extracts/re-extracts transcripts (with thinking blocks) into `.transcript.md` files
5. Updates `.staged-sessions` with current JSONL sizes

This is a lightweight I/O operation — no model calls, no Claude invocations.

### Scheduled Distillation (cron)

A separate cron job runs periodically (e.g., hourly or nightly) and:

1. Reads the domain registry (`firehose/REGISTRY.md`)
2. For each domain, scans `.context/sessions/` for `.transcript.md` files
3. Checks the source JSONLs for `[FIREHOSE]` markers — sessions with content after (or without) a marker need distillation
4. Invokes the distiller for domains with pending work
5. Logs results

This requires no interactive session, no running IDE, no parent process. The signal is on disk.

### Phase 1 — Minimal

- Headless `claude -p` with distillation system prompt (`distiller-prompt.md`)
- Writes canonical files with `status: proposed` frontmatter
- Human reviews and approves by editing frontmatter
- Manual `distill <domain>` invocation

### Phase 2 — Automation

- Cron job for scheduled distillation across registry
- `--re-distill` command for reprocessing
- Strategy selection from agent.md config
- Conflict report generation

### Phase 3 — Advanced

- Adversarial strategy implementation
- Distillation quality metrics (how often does the human reject proposals?)
- Distiller prompt versioning (track which prompt version produced each distillation)
- Corpus-wide re-distillation when the distiller improves

## Design Principles

1. **CC's JSONL is the source of truth.** Session JSONL files are the durable corpus — written continuously by CC, never modified by firehose except to append `[FIREHOSE]` markers. Transcripts are derived artifacts that can always be re-extracted.
2. **Transcripts over checkpoints.** The full session record (including thinking blocks) is the primary input for distillation. Checkpoints are attention markers — valuable but optional.
3. **Objective distillation.** The distiller forms its own view before considering the human and agent's perspectives. Assumes either may have lost the plot. The best truth wins.
4. **Staged, not direct.** Agents never write to canonical files. The distiller writes with an approval gate (frontmatter `status: proposed`).
5. **Standalone.** The distiller is not part of the agent or the orchestrator. It's a separate tool that reads and writes to the filesystem.
6. **Strategy is configuration.** The interface contract doesn't change when you swap strategies. Simple, careful, adversarial, custom — same inputs, same outputs.
7. **Human-compatible.** The filesystem is the interface. Humans can author session notes, review proposed diffs, and approve changes using their own tools. The `[FIREHOSE]` marker is visible in CC's conversation view.
8. **Conservative with decisions.** DECISIONS.md is append-only. The distiller adds but never removes or modifies. Revisit conditions are flagged, not acted upon.
9. **Provenance preserved.** Three perspectives (human, agent, distiller) coexist with clear provenance. Canonical files trace back to source sessions. The raw JSONL is always available for audit or re-derivation.
