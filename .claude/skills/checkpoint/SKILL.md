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

## Session file management

Checkpoints belong to a **session** — a coherent unit of work. The skill must determine whether to append to an existing session file or create a new one.

### Finding the current session

1. Scan `.context/sessions/` for `.md` files (excluding `.draft.md` and `.log`).
2. Parse YAML frontmatter. Look for a file with `status: active`.
3. If found, this is the current session — append the new checkpoint to it.
4. If no active session exists, create a new session file.

### Creating a new session file

1. Under `<domain-root>/.context/sessions/`, create a new markdown file:
   - Name: `<ISO-8601-timestamp>.md` (e.g. `2026-03-09T14-37-22.md`), using a filename-safe timestamp.
2. Write YAML frontmatter:

   ```yaml
   ---
   status: active
   created: <ISO-8601 timestamp>
   ---
   ```

### Writing a checkpoint entry

Append a checkpoint block to the session file:

```markdown
## Checkpoint: <timestamp>
- **Scope**: Briefly describe what part of the domain or work this covers.
- **Since last checkpoint**: Bullet list of what changed or was done.
- **Decisions made**: Bullet list of decisions made, with 1–2 lines of rationale each.
- **Open questions**: Bullet list of questions or uncertainties to carry forward.
- **Current thinking**: Short narrative of the current mental model.
- **Notes**: Any extra notes, including optional arguments passed to `/checkpoint`.
```

Populate these sections by summarizing the **recent conversation** and any relevant file edits since the last checkpoint, keeping the text concise but specific.

## Session closing behavior (`/checkpoint --close`)

If `$ARGUMENTS` includes `--close`:

1. Write the regular checkpoint entry as above.

2. Update the session file's frontmatter to `status: closed` and add `closed_at`:

   ```yaml
   ---
   status: closed
   created: 2026-03-10T14:37:22
   closed_at: 2026-03-10T16:52:00
   ---
   ```

3. Create a companion **memory draft** file:
   - Path: `<domain-root>/.context/sessions/<same-session-timestamp>.draft.md`

4. In the draft file, propose what should be remembered long-term:

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

5. Make it clear in the draft that these are the **agent's subjective assessment** — proposals, not canonical updates. The distiller will independently extract from the checkpoints and compare against this draft.

## Opportunistic closing

The agent may also close a session without `--close` being explicitly passed, when it senses work is winding down (e.g., user says goodbye, task is complete, conversation is wrapping up). In this case, update the frontmatter to `status: closed` and note in the checkpoint that the close was opportunistic.

If the session continues after an opportunistic close (meaningful new work occurs), reset the frontmatter to `status: active` before writing the next checkpoint.

## Never touch canonical memory directly

- Do **not** modify `.context/MEMORY.md` or `.context/DECISIONS.md` in this skill.
- Only write checkpoint entries and draft files in `.context/sessions/`.

When in doubt about structure or semantics, consult `domain-convention.md` and `distiller-spec.md` in the repo root.
