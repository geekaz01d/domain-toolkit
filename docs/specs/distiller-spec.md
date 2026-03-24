# Distiller Spec

## Overview

The distiller synthesizes session artifacts into domain memory. It runs **outside** of interactive sessions — scheduled, batched, or on-demand — reading the canonical record of what happened (session transcripts) and producing a curated synthesis for future sessions.

The distiller is a **second-order observer** (von Foerster). It does not observe the session directly — it observes the artifacts produced by the first-order participants (human and session agent). It is differently positioned, not unbiased. It has its own blind spots. Its value comes from temporal and processual separation — reading cold artifacts off disk, without the sunk-cost reasoning and recency bias of the interactive session.

In Beer's Viable System Model: the session agent is System 3 (inside-and-now, operational), the human is System 4 (outside-and-future, strategic), and the distiller functions as System 5 — mediating the S3-S4 dialectic to maintain identity coherence of the knowledge base. In Ashby's terms, the distiller performs **variety attenuation**: reducing the high-variety session transcript to the requisite variety for future sessions. Per the Law of Requisite Variety, the attenuator needs sufficient internal variety to distinguish signal from noise — the argument for a capable model, not a cheap filter.

## Precedents

The distiller draws on established patterns and emerging research. Naming them clarifies what is borrowed, what is adapted, and what is novel.

**Architecture Decision Records (ADRs).** DECISIONS.md is an ADR log. The append-only semantics, the status lifecycle (`active → deprecated → superseded`), and the revisit conditions all come from the ADR pattern (Nygard 2011; adopted by Microsoft, AWS, 18F/GSA). This is the most mature and validated pattern the distiller builds on.

**Blameless postmortems.** The isolation requirement — don't let the same agent that did the work also judge the work — is the same principle behind blameless post-incident reviews (Google SRE). Temporal separation from the session, structured analysis of artifacts, focus on what happened rather than attachment to outcomes. The distiller is an automated blameless postmortem for agent sessions.

**Constitutional AI.** The distiller's governance principles function like Anthropic's constitutional AI framework (Bai et al. 2022): a fixed set of rules that guide meta-evaluation of first-order outputs. The distiller prompt embeds principles (weight outcomes over reasoning, preserve human intent) that constrain synthesis the way a constitution constrains self-critique. The risk is the same: if the principles are wrong, the distiller enforces them blindly.

**Generative Agent reflection.** Park et al. (2023) introduced a reflection layer where agents generate higher-level summaries from stored experiences to inform future planning. The distiller is architecturally similar — post-session reflection over stored artifacts — but differs in that it runs as an isolated process (not the same agent reflecting on itself).

**Recursive summarization.** Xu et al. (2023) proposed iterative memory updates for long dialogues: each session's content is fused with prior memory to produce an updated summary, forming a memory chain. The distiller follows this pattern — each distillation builds on existing MEMORY.md + new transcripts.

**Multi-agent debate.** Du et al. (2023) showed that multiple LLM instances proposing and cross-reviewing solutions improves factuality. This is relevant to the adversarial synthesis strategy (Stage 2), where a second model reviews the first's proposals. The literature suggests structured iteration between models produces better results than single-pass synthesis.

**CoT unfaithfulness.** The spec's instruction to weight outcomes over reasoning traces is grounded in recent findings that LLM chain-of-thought is often post-hoc rationalization rather than faithful reasoning (Barez et al. 2025, Arcuschin et al. 2025). He et al. (2026) further show that LLMs have latent reasoning modes independent of explicit CoT. The distiller must treat thinking blocks as positioned artifacts, not transparent computation traces.

**Closest system-level comparators.** Hindsight (Latimer et al. 2024) organizes memory into four networks with retain/recall/reflect operations — the reflect operation maps to distillation. A-Mem (Xu et al. 2025, NeurIPS) uses Zettelkasten-style self-organizing memory with evolution. MemOS (2025) treats memory as a governed resource with provenance and access control. Mem0 performs intelligent consolidation with recency-based conflict resolution. None of these combine processual isolation, canonical permanence, and derived re-synthesizability — that combination appears to be novel.

## Governance

The distiller exists to serve a governance model. This section defines it.

### Core principle: humans author intent, agents are custodial

The human originates purpose, makes decisions, and steers direction. The agent maintains, executes, and preserves — but does not originate intent. This is not a safety guardrail. It is a claim about what produces better outcomes: humans are better at intent, direction, and judgment about what matters; agents are better at execution, recall, and thoroughness. The governance model allocates authority according to capability.

The distiller enforces this governance by ensuring human intent — as articulated in the session transcript — survives into synthesized domain memory. The human's decisions are the most important signal in the transcript. **Failure to capture and surface the human's decisions is a failure mode of the distiller.** A distillation that accurately summarizes what the agent did but loses what the human decided has failed its core function.

### What this means in practice

- **Session transcripts are the canonical record.** They preserve the human's articulated intent verbatim. The transcripts are not interpreted, not summarized — they are the actual words. This is a governance choice, not just an engineering one.
- **Synthesized files are derived, not canonical.** MEMORY.md and DECISIONS.md are the distiller's synthesis of the canonical record. They can be re-derived when the distiller improves. The session corpus cannot be re-derived — it just is.
- **Decisions are append-only with lifecycle statuses.** The distiller adds to DECISIONS.md but never modifies or removes entries. If a revisit condition is met, the distiller flags it. Following the ADR pattern, decisions carry a status: `active → deprecated → superseded`. Superseding a decision means adding a new decision that references the old one — the original entry is never modified or deleted.
- **First-order and second-order memory coexist.** The session agent writes first-order domain memory (STATE.md, session notes, CC auto-memory) during interactive sessions. The distiller produces second-order synthesis from the canonical record. Both contribute to the domain's knowledge layer.

## Terminology

| Term | Meaning |
|------|---------|
| **Canonical** | The verbatim session record (CC JSONL, transcripts). Source of truth. Not interpreted. |
| **Derived (first-order)** | Artifacts produced by the session agent during the session: CC native memory, tool outputs. Reflect the agent's in-session interpretation. Not reviewed. |
| **Synthesized (second-order)** | MEMORY.md, DECISIONS.md. Produced by the distiller from canonical and first-order sources. Human-validated. The operational interface future sessions read. |
| **Session agent** | The agent instance within an interactive session. Produces first-order artifacts. Custodial. |
| **Human** | The human participant. Author of intent. Their articulated direction in the transcript is authoritative. |
| **Distiller** | Second-order observer. Reads canonical and first-order artifacts. Produces synthesized state. Proposes; does not decide. |

## Artifact Layers

The system produces artifacts at three levels. Each level is written by a different process at a different order of observation.

### Canonical layer (the session record)

- **CC session JSONL** — the complete interaction record, written continuously by the CC runtime. Contains human messages (intent), agent messages (reasoning, including thinking blocks), and tool calls (actions). This is the source of truth for everything that happened.
- **Staged transcripts** (`.context/sessions/*.transcript.md`) — extracted from JSONL by the stager. A readable form of the canonical record. Derived but faithful — can always be re-extracted.

The canonical layer is **permanent and unreduced**. Sessions are the durable corpus. The distiller is a replaceable lens over this corpus.

### First-order layer (session agent artifacts)

- **CC native auto-memory** (`~/.claude/projects/<encoded-path>/memory/`) — memories the session agent writes via CC's built-in memory system. First-order: written from inside the session, carrying whatever biases and framing the agent held at the time. CC loads these automatically on every session start.

First-order artifacts reflect what happened and what the agent believed, not what should be remembered. They are raw material for synthesis, not authoritative.

### Synthesized layer (distiller output)

- **MEMORY.md** — curated domain knowledge for future sessions. Produced by the distiller, validated by the human.
- **DECISIONS.md** — append-only decision log with rationale and revisit conditions. Same governance: distiller proposes, human approves.

Synthesized artifacts are **derived**. They represent a second-order understanding of the domain, produced through dialectical synthesis of human intent and agent execution. They can be re-synthesized when the distiller improves.

### The memory conflict problem

CC's native memory and the domain kit's MEMORY.md serve different functions but occupy the same cognitive space for the session agent. Both are loaded on session start. When they diverge — and they will, because CC memory is first-order and unsynthesized — the session agent carries contradictory context. This is not a theoretical risk; it is a guaranteed reasoning burden that compounds over time.

This is the central architectural tension of Stage 1.

### CC memory controls (researched 2026-03-12)

CC officially supports three mechanisms for controlling its native memory:

| Mechanism | Scope | How |
|-----------|-------|-----|
| `autoMemoryEnabled: false` | Per-project | `.claude/settings.json` |
| `autoMemoryDirectory` | User-level only | `~/.claude/settings.json` or `~/.claude/settings.local.json`. Cannot be set per-project (security restriction). |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` | Global (env var) | Disables all auto-memory |

Additionally, an undocumented `CLAUDE_CODE_AUTO_MEMORY_PATH` env var exists (v2.1.64+) but lacks documentation on precedence rules. See [GitHub #30579](https://github.com/anthropics/claude-code/issues/30579).

**Key constraint**: `autoMemoryDirectory` is user-level only. It cannot be set per-domain. A multi-domain setup cannot redirect each domain's CC memory to its own `.context/` — the redirect is global.

### Resolution: harvest, don't compete

CC auto-memory is a first-order artifact — useful signal written by the session agent. Rather than disabling or redirecting it, the stager **harvests** CC auto-memory into `.context/` alongside session transcripts. The JSONL provides full provenance: every memory write is a tool call with a session ID and timestamp.

The session agent also writes directly to domain `.context/` files (STATE.md, MEMORY.md, DECISIONS.md) via system prompt governance. CC auto-memory and domain memory are not competing systems — they are both first-order outputs. The stager imports CC auto-memory into `.context/` so it travels with the domain.

The distiller (second-order) reads both when re-synthesizing. CC auto-memory is input, not authority.

## Stages

### Stage 0 — Status quo (CC native)

CC has its own session memory. It is machine-stored at `~/.claude/projects/<encoded-path>/memory/`, non-portable, and project-scoped. The session agent reads and writes it freely. There is no synthesis loop and no way to re-derive the memory from source material.

The domain kit addresses the portability and synthesis deficiencies while preserving CC auto-memory as a first-order input.

### Stage 1 — Domain-local portability (MVP)

Session artifacts are stored domain-local in `.context/` and become portable. The session agent reads synthesized domain memory on entry via the session-start hook. The canonical session record (JSONL/transcripts) lives alongside the synthesized files it feeds.

**Stage 1 establishes first-order domain memory** — the session agent writes directly to `.context/` during interactive sessions, CC auto-memory is harvested into `.context/` by the stager, and session transcripts are staged for the canonical record. No distiller needed for Stage 1.

**What Stage 1 delivers:**
- Session transcripts staged domain-local (`.context/sessions/`)
- CC auto-memory harvested into `.context/` (first-order, with provenance)
- Session agent writes STATE.md directly
- Session agent writes first-order MEMORY.md and DECISIONS.md via system prompt governance

### Stage 2 — Synthesis orchestration

The synthesis process becomes modular. We do not know what the best technique will be — it may differ by domain. Stage 2 provides an orchestration framework, not a single prompt.

**What Stage 2 delivers:**
- Pluggable strategies (single-model, multi-model, adversarial, custom)
- Strategy selection per domain via `persona.md`
- Multi-pass synthesis
- Conflict detection and reporting (`DISTILL-CONFLICTS.md`)
- Re-synthesis capability (reprocess corpus with improved prompt or model)

### Stage 2.5 — Automation

The synthesis loop runs unattended.

**What Stage 2.5 delivers:**
- Cron-driven transcript staging (`bin/stage-transcripts`)
- Cron-driven synthesis across the domain registry
- Batch processing (`distill-domain --all`)
- Synthesis markers in JSONL (high-water marks for incremental processing)
- No dependency on running IDE or interactive session

## Two Perspectives in the Transcript

The session transcript contains two first-order perspectives:

- **Human** (author of intent): steers the session, makes decisions, articulates direction. The transcript preserves this verbatim — the human's words are the authoritative record of intent.
- **Session agent** (custodial): executes, reasons through problems, produces artifacts. Thinking blocks and tool calls are operational evidence. Subject to completion bias, sunk-cost reasoning, and CoT unfaithfulness (Barez et al. 2025, Arcuschin et al. 2025) — the distiller interprets these as positioned artifacts, not transparent computation traces.

### How the distiller reads the transcript

1. **Read the full transcript** — including thinking blocks. Understand what was explored, what was tried, what worked, what didn't.
2. **Recognize human intent** — track what the human articulated, how direction evolved through the session. If the human changed direction mid-session, that is intent evolving, not error.
3. **Interpret agent reasoning** — weight outcomes and actions (what was committed, what tool calls produced) over reasoning traces (why the agent said it did something). Distinguish reasoning the agent explored and abandoned from conclusions it acted on.
4. **Synthesize:**
   - Human intent that should persist as decisions → `DECISIONS.md`
   - Knowledge and context that future sessions need → `MEMORY.md`
   - Contradictions between session material and existing synthesized state → `DISTILL-CONFLICTS.md`
   - If the distiller's interpretation of intent conflicts with what the human articulated → flag in DISTILL-CONFLICTS.md. The distiller does not silently override articulated intent.

## Access Boundaries

| Actor | Session transcripts | Domain memory files | CC session JSONL | CC native memory |
|-------|-------------------|-------------------|------------------|-----------------|
| **Session agent** | Never reads or writes. | Reads on entry. Writes first-order (STATE.md, MEMORY.md, DECISIONS.md). | Written by CC runtime. Agent unaware. | Reads on entry. Writes in-session (first-order). |
| **Stager** (`stage-transcripts`) | Writes (extracts from JSONL). | Never touches. | Reads (source of truth). | Harvests into `.context/` (imports with provenance). |
| **Distiller** | Reads (primary input). | Writes (second-order synthesis). | Appends `[DOMAIN-TOOLKIT]` marker on completion. | Reads (first-order evidence). |
| **Human** | Can author directly (drop a .md into sessions/). | Can edit directly. | Sees marker if resuming a distilled session. | Can edit directly. |

## Session Lifecycle

### Source of truth

Claude Code writes a JSONL file per session at `~/.claude/projects/<encoded-project-path>/<session-id>.jsonl`. This file contains everything: human messages, assistant messages (with thinking blocks), tool calls and results. It is written continuously by CC — every turn appends.

The **stager** (`bin/stage-transcripts`) extracts these JSONL files into readable `.transcript.md` files in `.context/sessions/`. The staged transcript is a derived artifact — the JSONL is the source of truth.

### Tracking state

Session state is tracked in `.context/sessions/.staged-sessions`, a TSV file:

```
<session_id>\t<jsonl_byte_size>
```

The stager updates this on every run. If the JSONL has grown (session was continued), the stager re-extracts and overwrites the transcript atomically.

### Synthesis marker

When the distiller finishes processing a session, it appends a **`[DOMAIN-TOOLKIT]` marker** directly to the CC session JSONL — a human-type message that serves three purposes:

1. **Human sees it** when browsing or resuming the session in CC
2. **Session agent sees it** if the session is continued — knows prior content has been captured
3. **Distiller sees it** on subsequent runs — the marker is the high-water mark

The marker format:

```
[DOMAIN-TOOLKIT] ─────────────────────────────────────
⚑ Session synthesized at <timestamp>

Content above this line has been processed into
MEMORY.md and DECISIONS.md for this domain.

If you continue this session, new content will need
to be synthesized separately.
──────────────────────────────────────────────────────
```

This is appended as a regular human message (`isMeta: false`) so it renders visibly in CC's conversation view.

### Continued sessions

If a session is continued after synthesis:

1. New content lands in the JSONL after the `[DOMAIN-TOOLKIT]` marker
2. The stager detects the JSONL has grown (size > recorded size) and re-extracts the full transcript
3. The distiller, on its next run, sees the marker and knows to process only content after it

### Re-synthesis

The session JSONL corpus is the durable asset. To re-synthesize:

- Remove the `[DOMAIN-TOOLKIT]` marker from the JSONL (or the stager entry from `.staged-sessions`)
- The distiller will reprocess the full session

Useful when the distiller prompt has improved, a better model is available, or synthesized files have drifted.

## Session-End Hook

A CC `SessionEnd` hook triggers staging and auto-memory harvesting when a session closes. This is the primary mechanism for internalising session artifacts into domain context storage.

### Hook configuration

Registered in `~/.claude/settings.json` alongside the existing `SessionStart` hook:

```json
"SessionEnd": [
  {
    "matcher": "",
    "hooks": [
      {
        "type": "command",
        "command": "\"$HOME\"/.claude/hooks/session-end.sh",
        "async": true
      }
    ]
  ]
]
```

`async: true` is critical — the hook runs in the background after the session closes. No timeout pressure. The session does not wait for staging to complete.

### Hook input

CC provides JSON on stdin:

```json
{
  "session_id": "<uuid>",
  "transcript_path": "/home/user/.claude/projects/<encoded>/<session-id>.jsonl",
  "cwd": "/path/to/domain",
  "hook_event_name": "SessionEnd",
  "reason": "prompt_input_exit"
}
```

`reason` values: `clear`, `resume`, `prompt_input_exit`, `logout`, `bypass_permissions_disabled`, `other`.

### Hook behavior

The session-end hook performs two jobs for managed domains (those with `.context/sessions/`):

**1. Stage the session transcript**

Run `stage-transcripts` scoped to the just-ended session's domain. The stager reads the session-index, finds the JSONL at `transcript_path`, extracts a `.transcript.md`, and updates `.staged-sessions`.

**2. Harvest CC auto-memory**

Copy CC auto-memory files from `~/.claude/projects/<encoded>/memory/` into `.context/memory/`, preserving filenames. The harvest is additive — new or modified files are copied, existing files are not deleted. A `.harvest-log` file in `.context/memory/` records what was harvested, when, and from which session, providing provenance.

### Environment coverage

| Environment | SessionEnd fires? | Hook covers? |
|-------------|------------------|-------------|
| CLI | Yes | Yes |
| Cursor / VS Code | Yes | Yes |
| Claude Desktop (Code tab) | Yes | Yes |
| Claude Cowork | No (sandboxed runtime) | No — use cron fallback or `import-session` |

### Fallback: cron

A cron job (`bin/stage-transcripts`) runs every 15 minutes as a fallback. It catches:

- Sessions where the hook failed or was not installed
- Cowork sessions (if the stager is extended to scan Cowork sandbox paths)
- Sessions that were continued after staging (JSONL grew)

The cron and hook are idempotent — running both on the same session produces the same result. The `.staged-sessions` state file prevents duplicate work.

### Session-index enhancement

The session-start hook records `cwd` in session-index entries alongside `session_id`, `transcript_path`, and `source`. This enables the stager to reconstruct JSONL paths on a different machine (where `transcript_path` may not exist) using `cwd` to compute the encoded project path.

```json
{
  "session_id": "<uuid>",
  "transcript_path": "/home/user/.claude/projects/<encoded>/<uuid>.jsonl",
  "cwd": "/home/user/sources/domain-toolkit",
  "source": "startup",
  "started": "2026-03-22T03:38:14Z"
}
```

## Interface Contract

**Input:**
- Session transcripts from `.context/sessions/*.transcript.md` (includes thinking blocks)
- CC native auto-memory (`~/.claude/projects/<encoded-path>/memory/`) — first-order operational memory the session agent carried into and updated during the session
- Current synthesized state: `MEMORY.md`, `DECISIONS.md`
- Domain context: `README.md`, `STATE.md` (for grounding)

**Output:**
- Updated `MEMORY.md` (with synthesis provenance frontmatter)
- Updated `DECISIONS.md` (same frontmatter convention)
- Conflict report in `DISTILL-CONFLICTS.md` (if changes contradict existing state)

**Side effects:**
- `[DOMAIN-TOOLKIT]` marker appended to the CC session JSONL (high-water mark)
- `.staged-sessions` updated to reflect processed state

## Synthesis Metadata

The distiller annotates synthesized files with provenance frontmatter:

```yaml
---
synthesized_at: 2026-03-10T18:30:00
source_sessions:
  - 2026-03-10T14-37-22
  - 2026-03-10T16-52-00
---
```

This enables re-synthesis: the frontmatter records which sessions contributed to the current state, and when synthesis last ran.

## Trigger Modes

| Mode | Trigger | Execution Context | Stage |
|------|---------|-------------------|-------|
| **Manual** | `distill-domain <domain>` or `/distill-domain` skill | From any terminal or session. Human-initiated. | 1 |
| **Scheduled** | Cron job detects staged transcripts without `[DOMAIN-TOOLKIT]` markers | System-level. No interactive session. | 2.5 |
| **Batch** | `distill-domain --all` | Iterates registry. Processes all domains with pending work. | 2.5 |

The **scheduled cron job** (Stage 2.5) walks the domain registry, checks each domain's `.context/sessions/` for transcripts that haven't been fully synthesized (by scanning the source JSONLs for `[DOMAIN-TOOLKIT]` markers), and runs synthesis against those domains. This decouples synthesis from the interactive session entirely.

The signal is: **staged transcripts exist whose source JSONLs have content after (or without) a `[DOMAIN-TOOLKIT]` marker**.

## Synthesis Strategies (Stage 2)

The distiller's internal processing is a **black box with a pluggable strategy**. The interface contract stays the same regardless of strategy. Strategies are specified in persona.md or as CLI arguments.

We do not yet know what the best synthesis technique is. It may vary by domain — a high-stakes domain with complex decisions may need adversarial multi-pass review, while a routine domain may be well-served by a single model call. The framework must support experimentation.

### Simple (default for Stage 1)

Single model call. Prompt includes session transcript, existing synthesized files, and instructions to produce structured updates.

- Model: configurable, default **Opus-tier** — synthesis is judgment-heavy, not mere summarization. The distiller must recognize human intent, interpret agent reasoning, and synthesize both.
- Can be downgraded to Sonnet for routine/low-stakes domains once a proven prompt exists

### Adversarial

Multi-model or multi-pass review. Grounded in multi-agent debate literature (Du et al. 2023) and dialectical prompting (Abdali et al. 2025, who implement thesis–antithesis–synthesis cycles in LLMs). Computational argumentation frameworks (Fröhlich et al. 2024) suggest that feeding claims through formal argument graphs produces more robust outputs than single-pass reasoning.

- Pass 1: generate synthesis (any model)
- Pass 2: adversarial review — a second model (or same model, different prompt) evaluates the proposals against existing synthesized state, checks for conflicts, omissions, mischaracterizations
- Pass 3 (optional): reconciliation if the reviewer flagged issues

### Custom

Human-defined strategy. The distiller accepts a strategy script or prompt template, enabling arbitrary processing pipelines. This is the extensibility point — custom flows, multiple models, human-in-the-loop at any stage.

## Prompt Structure

The distiller prompt (for the simple strategy) follows this general shape:

```
You are a synthesis agent — a second-order observer. You read session
transcripts after the fact, from outside the session. You are differently
positioned from the participants, not objective. You have your own blind
spots. Your value comes from temporal separation and fresh perspective.

Your governance model: humans author intent, agents are custodial.
The human's words in the transcript are the authoritative record of intent.
The agent's reasoning and actions are operational evidence — useful but
subject to completion bias and CoT unfaithfulness. Weight outcomes and
actions over reasoning traces.

Failure to capture and surface the human's decisions is a failure of
this synthesis. If the human articulated a decision, direction change,
or judgment call, it MUST appear in the output.

## Existing Synthesized State

### MEMORY.md
<contents of current MEMORY.md>

### DECISIONS.md
<contents of current DECISIONS.md>

## CC Native Memory (first-order, session agent)
<contents of ~/.claude/projects/<encoded-path>/memory/>

Note: This is first-order operational memory — written by the session agent,
without review. If it diverges from synthesized MEMORY.md, flag the discrepancy.

## Session Transcript
<full transcript including thinking blocks, tool calls, and conversation>

## Instructions

1. Read the full transcript. Understand what was explored, what was
   tried, what worked, what didn't.
2. Recognize human intent — track what the human articulated and how
   their direction evolved. If direction changed mid-session, that is
   intent evolving, not error.
3. Interpret agent reasoning — distinguish explored-and-abandoned
   reasoning from conclusions the agent acted on. Thinking blocks are
   generated outputs, not transparent computation traces.
4. Identify decisions for DECISIONS.md — with rationale and revisit
   conditions. Decisions reflect human intent as articulated in the
   transcript. This is the most important output.
5. Identify new knowledge for MEMORY.md — things future sessions need.
6. Flag any conflicts between session material and existing synthesized state.
7. Flag any divergence between CC native memory and synthesized MEMORY.md.
8. Preserve the existing structure of MEMORY.md sections.
9. DECISIONS.md entries are append-only — never modify existing entries.
10. If a previous decision's revisit conditions appear to be met, flag explicitly.
11. If your interpretation of intent conflicts with what the human
    articulated, flag it — do not silently override.

## Output Format

Produce three sections:

### MEMORY.md Updates
[Updated MEMORY.md content, preserving existing structure with new material merged in]

### DECISIONS.md Updates
[New entries only, in the standard format]

### Conflicts
[Any contradictions between session material and existing synthesized state,
divergence between CC native memory and synthesized state, or between your
interpretation and the human's articulated intent]
```

## Conflict Handling

Conflicts arise when session material contradicts existing synthesized state. Examples:

- Session agent concluded X, but MEMORY.md records Y from a prior session
- A new decision contradicts or supersedes a previous decision
- Session material suggests a revisit condition has been met
- CC native memory diverges from synthesized MEMORY.md

The distiller surfaces conflicts explicitly in `DISTILL-CONFLICTS.md`. It does not silently resolve them. When conflicts are detected, the most recent session material wins (last-write-wins) and the conflict is logged for human visibility.

## What the Distiller Reads

1. **Session transcripts** (`<timestamp>.transcript.md`): The canonical session record extracted from CC's JSONL, including human messages, assistant messages, thinking blocks, and tool call summaries. Primary source material.
2. **CC native auto-memory** (`~/.claude/projects/<encoded-path>/memory/`): First-order memories the session agent wrote or updated. Reveals what the agent believed was important enough to persist — useful as evidence, not authoritative. Divergence from synthesized MEMORY.md is flagged.

### Processing order

1. Read existing synthesized state (MEMORY.md, DECISIONS.md)
2. Read CC native memory (first-order context)
3. Read session transcripts, chronologically
4. Run the selected strategy
5. Write updated synthesized files (with provenance frontmatter)
6. Harvest CC native memory (stage into `.context/` with session provenance)
7. Append `[DOMAIN-TOOLKIT]` synthesis marker to the CC session JSONL
8. Write `DISTILL-CONFLICTS.md` if conflicts were detected

### Human-authored session notes

The distiller does not care who authored session artifacts. If a human drops a markdown file into `.context/sessions/`, it gets processed alongside transcripts. The filesystem is the interface — not the chat.

## CLI Interface

```
distill-domain <domain>                     # synthesize a single domain
distill-domain --all                        # synthesize all domains with pending sessions
distill-domain <domain> --strategy careful  # override strategy for this run
distill-domain <domain> --model opus        # override model for this run
distill-domain <domain> --re-synth          # reprocess corpus (remove markers, re-run)
distill-domain <domain> --dry-run           # show what would be processed, don't execute
distill-domain --pending                    # list all domains with unsynthesized sessions
```

## Implementation Notes

### Isolation Requirement

The distiller **must** run in isolated context — a separate Claude Code invocation with no access to the interactive session's conversation history. This is a debiasing mechanism, not an implementation convenience. The session agent carries completion bias and sunk-cost reasoning. The distiller reads cold artifacts off disk and evaluates them without attachment to outcomes.

Invocation:

```bash
cd /path/to/domain && claude -p \
  --system-prompt-file ~/sources/domain-toolkit/distiller-prompt.md \
  "Synthesize this domain"
```

Print mode (`-p`), fresh session, no shared context. The distiller reads `.context/sessions/` and `.context/MEMORY.md` / `DECISIONS.md` from disk. Running from the domain root avoids cross-project permission issues.

### Transcript Staging (Stage 2.5)

A cron job (`bin/stage-transcripts`) runs periodically and:

1. Reads the domain registry (`~/.claude/domain-toolkit/REGISTRY.yaml`)
2. For each domain, reads `.context/sessions/session-index.jsonl`
3. For each session, checks if the source JSONL has grown since last staging
4. Extracts/re-extracts transcripts (with thinking blocks) into `.transcript.md` files
5. Updates `.staged-sessions` with current JSONL sizes

This is a lightweight I/O operation — no model calls, no Claude invocations.

### Scheduled Synthesis (Stage 2.5)

A separate cron job runs periodically (e.g., hourly or nightly) and:

1. Reads the domain registry (`~/.claude/domain-toolkit/REGISTRY.yaml`)
2. For each domain, scans `.context/sessions/` for `.transcript.md` files
3. Checks the source JSONLs for `[DOMAIN-TOOLKIT]` markers — sessions with content after (or without) a marker need synthesis
4. Invokes the distiller for domains with pending work
5. Logs results

This requires no interactive session, no running IDE, no parent process. The signal is on disk.

## Design Principles

1. **Humans author intent; agents are custodial.** The governance model. The human originates purpose and direction. The agent maintains, executes, and preserves. The distiller serves this model — it ensures human intent survives into synthesized form. Failure to capture human decisions is a failure mode.
2. **Session JSONL is canonical.** Session JSONL files are the durable corpus — written continuously by CC, never modified by domain-toolkit except to append `[DOMAIN-TOOLKIT]` markers. Everything else is derived.
3. **Synthesis, not purification.** The distiller produces a dialectical synthesis of human intent and agent execution — not a distilled essence. The output is a new thing produced from the tension between two perspectives, validated by the human.
4. **Second-order observation, not objectivity.** The distiller is differently positioned — it reads cold artifacts from outside the session. It has its own blind spots. Its value comes from temporal separation, not from a claim to neutrality.
5. **Two orders of observation.** First-order: the session agent writes domain memory during interactive sessions (STATE.md, MEMORY.md, DECISIONS.md). Second-order: the distiller re-synthesizes from the canonical record. Both contribute; the distiller can improve what the session agent wrote.
6. **Standalone.** The distiller is not part of the agent or the orchestrator. It's a separate process that reads and writes to the filesystem.
7. **Strategy is configuration.** The interface contract doesn't change when you swap strategies. Same inputs, same outputs. The orchestration framework supports experimentation.
8. **Human-compatible.** The filesystem is the interface. Humans can author session notes, edit memory directly, and inspect conflicts using their own tools.
9. **Conservative with decisions.** DECISIONS.md is append-only. The distiller adds but never removes or modifies. Revisit conditions are flagged, not acted upon. Decisions are authored intent — they belong to the human.
10. **Corpus is permanent; distiller is replaceable.** Sessions are the durable asset. Synthesized files can always be re-derived. When the distiller improves, the corpus gets re-synthesized. This is by design — the lens improves independently of what it observes.

## Known Limitations

Acknowledged gaps and risks. Not blockers for Stage 1, but constraints the design must eventually address.

### MEMORY.md growth (no compaction strategy)

MEMORY.md grows monotonically — new knowledge is added, nothing is removed. Over time it will consume significant context budget on every session start and every distillation call, and become noisy as outdated knowledge accumulates alongside current knowledge. The spec needs a compaction or pruning mechanism. Options include tiered memory (hot/warm/cold), periodic re-synthesis of MEMORY.md itself, explicit archive sections loaded selectively, or size-based triggers that flag when MEMORY.md exceeds a threshold. This is the most important scaling gap.

### Auto-compaction degrades canonicality

The spec claims session JSONL is the canonical, verbatim record. However, Claude Code auto-compacts conversations when they approach context limits (~167K tokens), replacing earlier messages with summaries. The JSONL therefore contains compacted summaries for long sessions, not the original messages. Information lost to compaction is unrecoverable. The canonical record has gaps the spec must acknowledge. Mitigation: the stager should run frequently (cron every 15 minutes) to capture pre-compaction transcript state, providing a secondary canonical record that preserves content the JSONL may later compact. This trades strict single-source-of-truth for practical information preservation.

### First-order / second-order divergence

When the distiller re-synthesizes, its output may diverge from what the session agent wrote as first-order memory. This is expected — the distiller has a different perspective. The distiller's synthesis overwrites first-order memory (last-write-wins) and logs the divergence in DISTILL-CONFLICTS.md for visibility.

### Re-synthesis cost at scale

"Re-synthesize everything when the distiller improves" is practical for small corpora (< 100 sessions, ~$50-100 at Opus). At 1,000+ sessions it becomes expensive (~$500-1,000) and slow. A more practical approach: selective re-synthesis of sessions that produced decisions or significant memory entries, or re-synthesize only the most recent N sessions and treat older synthesis as stable.

### No quality evaluation framework

There is no benchmark or metric for "did the distiller capture the human's intent correctly?" Without this, improving the distiller prompt is guesswork. Future work should establish evaluation criteria — factual coverage, decision capture rate, alignment with human intent — and test distiller outputs against them.

### Distiller bias

The spec acknowledges the distiller "has its own blind spots" but provides no mechanism for detecting or correcting systematic bias. If the distiller consistently underweights certain types of human intent (e.g. aesthetic preferences vs. technical decisions), this compounds across sessions. Adversarial strategies (Stage 2) and ensemble distillers are potential mitigations, but no detection mechanism exists.

## References

- Abdali et al. (2025) — "Self-reflecting LLM: A Hegelian Dialectical Approach" — thesis/antithesis/synthesis prompting
- Arcuschin et al. (2025) — "CoT Not Always Faithful" — LLMs produce contradictory post-hoc rationalizations
- Bai et al. (2022) — "Constitutional AI" (Anthropic) — LLM self-critique with fixed constitutional rules
- Barez et al. (2025) — "CoT Is Not Explainability" (Oxford) — chain-of-thought can be unfaithful
- Du et al. (2023) — "Improving Factuality and Reasoning through Multiagent Debate"
- Fröhlich et al. (2024) — "ArgLLM" — computational argumentation (dialectical logic) guiding LLM output
- He et al. (2026) — "Reasoning Beyond Chain-of-Thought" — latent reasoning modes independent of explicit CoT
- Latimer et al. (2024) — "Hindsight" — four-tier agentic memory with retain/recall/reflect operations
- Nygard (2011) — Architecture Decision Records — append-only decision logging with status lifecycle
- Park et al. (2023) — "Generative Agents" — reflection layer over stored experiences
- Xu et al. (2023) — "Recursive Summarizing for Long Dialogue" — iterative memory-augmented conversation
- Xu et al. (2025) — "A-Mem" (NeurIPS) — Zettelkasten-style self-organizing agentic memory
