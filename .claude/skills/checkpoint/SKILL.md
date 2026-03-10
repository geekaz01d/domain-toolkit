---
name: checkpoint
description: Capture a structured checkpoint for the current domain session into .context/sessions/. Use /checkpoint for mid-session snapshots and /checkpoint --close at the end of a session.
disable-model-invocation: true
argument-hint: "[--close] [optional-note]"
---

You are implementing the **`/checkpoint`** command from `orchestrator-architecture.md` and `domain-convention.md` as a Claude Code skill.

This skill writes **structured session artifacts** under `.context/sessions/` for the current domain. It must **never** write directly to `MEMORY.md` or `DECISIONS.md`.

## How to interpret arguments

- If `$ARGUMENTS` contains `--close`, treat this as a **session-closing checkpoint**.
- Any other arguments can be treated as an optional human note about what is being checkpointed.

## Determine the domain root and context

1. Assume the current working directory is inside a firehose domain.
2. Walk up from the current directory until you find a folder that contains:
   - `README.md`
   - `.context/` directory
3. Treat that folder as the **domain root**.

If no such folder exists, explain that this skill expects to be run inside a firehose domain and do nothing else.

## Write a structured checkpoint file

1. Under `<domain-root>/.context/sessions/`, create a new markdown file:
   - Name: `<ISO-8601-timestamp>.md` (e.g. `2026-03-09T14-37-22.md`), using a filename-safe timestamp.
2. In that file, write a checkpoint in the following structure:

   ```markdown
   ## Checkpoint: <timestamp>
   - **Scope**: Briefly describe what part of the domain or work this covers.
   - **Since last checkpoint**: Bullet list of what changed or was done.
   - **Decisions made**: Bullet list of decisions made, with 1–2 lines of rationale each.
   - **Open questions**: Bullet list of questions or uncertainties to carry forward.
   - **Current thinking**: Short narrative of the current mental model.
   - **Notes**: Any extra notes, including optional arguments passed to `/checkpoint`.
   ```

3. Populate these sections by summarizing the **recent conversation** and any relevant file edits since the last checkpoint, keeping the text concise but specific.

## Session closing behavior (`/checkpoint --close`)

If `$ARGUMENTS` includes `--close`:

1. In addition to the regular checkpoint file, create a **memory draft** file:
   - Path: `<domain-root>/.context/sessions/<same-timestamp>.draft.md`
2. In the draft file, propose what should be remembered long-term, following the structure from `distiller-spec.md`:

   ```markdown
   ## Proposed Domain Understanding
   [Key updates to how we understand this domain]

   ## Proposed Key Context
   [New facts, constraints, or preferences that should live in MEMORY.md]

   ## Proposed Open Threads
   [Threads that should be carried forward between sessions]

   ## Proposed Decisions
   [Decisions that might belong in DECISIONS.md, with context and revisit conditions]
   ```

3. Make it clear in the draft that these are **proposals**, not canonical updates. The distiller will decide what to merge into `MEMORY.md` and `DECISIONS.md`.

## Never touch canonical memory directly

- Do **not** modify `.context/MEMORY.md` or `.context/DECISIONS.md` in this skill.
- Only write checkpoint and draft files in `.context/sessions/`.

When in doubt about structure or semantics, consult `domain-convention.md` and `distiller-spec.md` in the repo root.

