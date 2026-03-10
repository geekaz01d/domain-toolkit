---
name: distill-domain
description: Run the firehose distillation pipeline for a single domain by turning session artifacts into proposed MEMORY.md and DECISIONS.md updates.
disable-model-invocation: true
context: fork
model: opus
argument-hint: "[domain-path]"
---

You are implementing the **distiller** described in `distiller-spec.md` as a Claude Code skill for a single domain.

**You run in an isolated context.** You have no access to the conversation that produced the session artifacts you are processing. This is by design — the distiller must be objective. Your only inputs are the files on disk described below. Do not assume, infer, or hallucinate any session context beyond what is written in the checkpoint and draft files.

This skill:

- Reads canonical files (`MEMORY.md`, `DECISIONS.md`) and unprocessed session artifacts.
- Produces **proposed** updates (`MEMORY.md.proposed`, `DECISIONS.md.proposed`) and a conflict report.
- Moves processed session artifacts into `sessions/processed/` once proposals are written.

It must respect the **review mode** configured in `agent.md` (`memory_review: manual | flag | auto`), but should start conservatively with `manual` unless clearly configured otherwise.

## Model selection and strategy

This skill does not hardcode a model. The appropriate model depends on the **distillation strategy** from `agent.md` (or CLI override):

- **simple** (default): Haiku-tier. Straightforward summarization, cheap and fast.
- **careful**: Sonnet or Opus. Used when the domain has high-stakes decisions or complex, layered context where nuance and conflict detection matter.
- **adversarial**: Multi-pass. First pass generates proposals (any model), second pass reviews them against canonical state with a different prompt or model.

During early use (before you trust the pipeline), prefer running at **Sonnet-tier or above** regardless of configured strategy. Haiku is an optimization you make after validating that distillation quality meets your bar. Downgrade to Haiku once you've seen enough `.proposed` outputs to trust the simpler model.

## How to interpret arguments

- If `$ARGUMENTS` is provided, treat `$0` as the **domain root path** (relative or absolute).
- If no arguments are provided, treat the **current working directory** as the domain root.

Always normalize to the domain root before operating.

## Inputs

Under the domain root, expect:

- `README.md` and optionally `.context/STATE.md` for grounding.
- `.context/MEMORY.md` – current canonical memory.
- `.context/DECISIONS.md` – current canonical decision log.
- `.context/sessions/` – session artifacts:
  - `*.md` checkpoint files.
  - `*.draft.md` memory drafts (optional).
  - `*.log` raw transcripts (rarely needed).
  - `processed/` subdirectory for already-distilled sessions.

If any canonical file is missing, create a minimal placeholder and proceed, noting this in the proposals.

## Distillation prompt structure

When performing the distillation reasoning, follow the simple strategy from `distiller-spec.md`:

1. Read existing canonical state:
   - `MEMORY.md`
   - `DECISIONS.md`
2. Read all **unprocessed** session artifacts from `.context/sessions/` (excluding the `processed/` folder), in chronological order:
   - Checkpoint `.md` files.
   - `.draft.md` memory drafts, if present.
3. Use the following logical structure for your internal reasoning:

   - **Existing Canonical State**
     - Current memory and decisions.
   - **Session Artifacts**
     - Checkpoints and drafts since the last distillation.
   - **Instructions**
     - Identify new knowledge, context, and preferences that should persist.
     - Identify decisions made, with rationale and revisit conditions.
     - Flag conflicts with existing canonical state.
     - Preserve the structure of `MEMORY.md`.
     - Append-only semantics for `DECISIONS.md`.

4. Produce three conceptual outputs:
   - Updated `MEMORY.md` content.
   - New `DECISIONS.md` entries.
   - A list of **conflicts** or potential revisits.

## Writing proposed files

1. Write the proposed updated memory file to:

   - `.context/MEMORY.md.proposed`

   The content should be a complete, self-contained `MEMORY.md` body with the same section structure, updated to include new knowledge and open threads.

2. Write proposed new decisions to:

   - `.context/DECISIONS.md.proposed`

   This file should contain **only** new decision entries, each using the standard format:

   ```markdown
   ## <date>: <decision title>
   - **Context**: ...
   - **Alternatives considered**: ...
   - **Deciding factors**: ...
   - **Revisit if**: ...
   ```

3. If you detect conflicts between new material and existing canonical state, create a small conflict report at:

   - `.context/DISTILL-CONFLICTS.md`

   Briefly describe:

   - The conflicting items.
   - Which previous decisions or memory entries they clash with.
   - Whether you think the prior material should be revisited.

## Respect review mode

Read `agent.md` and look for a `memory_review` setting:

- `manual` (default if missing):
  - Only write `.proposed` files and the conflict report.
  - Do **not** modify `MEMORY.md` or `DECISIONS.md` directly.
- `flag`:
  - You may auto-merge clearly non-conflicting, low-risk updates into `MEMORY.md` while leaving `.proposed` and conflicts for review.
  - Be conservative; when in doubt, prefer `manual` behavior.
- `auto`:
  - You may treat the proposed updates as authoritative:
    - Overwrite `MEMORY.md` with the updated content.
    - Append new entries to `DECISIONS.md`.
  - Still write `.proposed` files and conflicts so there is an audit trail.

When first wiring up this skill, favor `manual` usage until the user explicitly sets a different mode.

## Mark sessions as processed

After successfully writing proposals:

1. Move all session checkpoint and draft files that were included in this run into:

   - `.context/sessions/processed/`

2. Leave raw `.log` files alone unless the user has asked you to archive or delete them.

## Summary for the user

At the end of the skill run, summarize in chat:

- Domain root path.
- Number of session artifacts processed.
- Whether `.proposed` files were written.
- Whether any conflicts were detected.
- Whether any canonical files were auto-updated (only in non-manual modes).

If you are unsure about any semantics, consult `distiller-spec.md` in the repo root and follow it as the source-of-truth.

