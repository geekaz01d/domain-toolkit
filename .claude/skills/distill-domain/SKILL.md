---
name: distill-domain
description: Run the domain-toolkit distillation pipeline for a single domain — second-order re-synthesis of MEMORY.md and DECISIONS.md from session transcripts and first-order artifacts.
user-invocable: false
context: fork
model: opus
argument-hint: "[domain-path] [--re-synth] [--strategy simple|adversarial|custom]"
---

You are implementing the **distiller** described in `distiller-spec.md` as a Claude Code skill for a single domain.

**You run in an isolated context.** You have no access to the conversation that produced the session artifacts you are processing. This is by design — the distiller must be objective. Your only inputs are the files on disk described below. Do not assume, infer, or hallucinate any session context beyond what is written in the session and draft files.

This skill:

- Reads domain memory files (`MEMORY.md`, `DECISIONS.md`), CC auto-memory, and session transcripts.
- Produces second-order re-synthesized domain memory with provenance frontmatter.

The distiller writes directly — there is no review gate. Conflicts are logged in `DISTILL-CONFLICTS.md`.

> **Note:** The session tracking mechanism (how the distiller knows which sessions have been processed) is under revision. `distiller-spec.md` defines a JSONL marker approach. This skill currently uses frontmatter-based tracking as an interim mechanism. See `distiller-spec.md` for the target design.

## Model selection and strategy

This skill does not hardcode a model. The appropriate model depends on the **distillation strategy** from `persona.md` (or CLI override):

- **simple** (default): Single model call. Opus-tier — synthesis is judgment-heavy, not mere summarization. Can be downgraded to Sonnet for routine/low-stakes domains once a proven prompt exists.
- **adversarial**: Multi-pass. First pass generates proposals (any model), second pass reviews them against synthesized state with a different prompt or model.
- **custom**: Human-defined strategy script or prompt template.

During early use (before you trust the pipeline), prefer running at **Sonnet-tier or above** regardless of configured strategy.

## How to interpret arguments

If `$ARGUMENTS` is `--help`, `--usage`, or `-h`, print this usage summary and stop:

```
distill-domain — Distillation pipeline

Usage: /distill-domain [domain-path] [--re-synth] [--strategy simple|adversarial|custom]

Options:
  --re-synth              Reset session tracking and reprocess all sessions
  --strategy <name>       Override the distillation strategy for this run
```

- If `$ARGUMENTS` is provided, treat the first positional argument as the **domain root path** (relative or absolute).
- If no positional argument is provided, treat the **current working directory** as the domain root.
- `--re-synth`: Reset session tracking and reprocess all sessions from scratch.
- `--strategy <name>`: Override the distillation strategy for this run.

Always normalize to the domain root before operating.

## Inputs

Under the domain root, expect:

- `README.md` and optionally `.context/STATE.md` for grounding.
- `.context/MEMORY.md` – current canonical memory.
- `.context/DECISIONS.md` – current canonical decision log.
- `persona.md` – agent identity and behavioural settings.
- `.claude/domain-toolkit/domain.yaml` – domain manifest.
- `.context/sessions/` – session artifacts with YAML frontmatter:
  - `*.md` session notes.
  - `*.draft.md` memory drafts (the agent's subjective view).
  - `*.transcript.md` staged transcripts (extracted from CC JSONL by the stager).

If any canonical file is missing, create a minimal placeholder and proceed, noting this in the proposals.

## Identifying sessions to process

1. Scan `.context/sessions/` for all `.md` files (excluding `.draft.md` and `.transcript.md` files).
2. Parse YAML frontmatter from each file.
3. Select files with `status: closed` (these are ready for distillation).
4. If `--re-synth` was passed, first reset any `status: distilled` files to `status: closed`.
5. If no `closed` sessions are found, report this and exit — nothing to distill.
6. Sort selected files chronologically.

## Distillation reasoning

Follow the simple strategy from `distiller-spec.md`:

1. Read existing canonical state:
   - `MEMORY.md`
   - `DECISIONS.md`
2. Read all `closed` session files, chronologically.
3. Read any companion `.draft.md` files for those sessions.
4. Reason through:

   - **Existing Canonical State** — current memory and decisions.
   - **Session Artifacts** — session notes and drafts since last distillation.
   - **Agent's subjective view** — compare the agent's memory drafts against your own extraction. Note agreement and disagreement.
   - **Instructions**:
     - Identify new knowledge, context, and preferences that should persist.
     - Identify decisions made, with rationale and revisit conditions.
     - Flag conflicts with existing canonical state.
     - Preserve the structure of `MEMORY.md`.
     - Append-only semantics for `DECISIONS.md`.

5. Produce three conceptual outputs:
   - Updated `MEMORY.md` content.
   - New `DECISIONS.md` entries (if any).
   - A list of **conflicts** or potential revisits (if any).

## Writing output

1. Write the updated `MEMORY.md` with provenance frontmatter:

   ```yaml
   ---
   synthesized_at: <ISO-8601 timestamp>
   source_sessions:
     - <timestamp of each processed session>
   ---
   ```

   The content should be a complete, self-contained `MEMORY.md` body with the same section structure, updated to include new knowledge and open threads.

2. Write the updated `DECISIONS.md` with the same frontmatter pattern. Append new entries to the existing content. Never modify or remove existing entries.

3. If conflicts were detected, write `.context/DISTILL-CONFLICTS.md` describing:
   - The conflicting items.
   - Which previous decisions or memory entries they clash with.
   - Whether the prior material should be revisited.

## Mark sessions as distilled

After successfully writing output:

1. Update the frontmatter of each processed session file to `status: distilled` and add `distilled_at: <timestamp>`.
2. Do **not** move, rename, or delete session files. They are permanent.
3. Leave `.draft.md` and `.transcript.md` files untouched (they don't have lifecycle frontmatter).

## Summary for the user

At the end of the skill run, summarize in chat:

- Domain root path.
- Number of session artifacts processed.
- Whether domain memory files were updated.
- Whether any conflicts were detected (logged in DISTILL-CONFLICTS.md).
- Whether any disagreements were found between first-order memory and distiller synthesis.

If you are unsure about any semantics, consult `docs/specs/distiller-spec.md` and follow it as the source-of-truth.
