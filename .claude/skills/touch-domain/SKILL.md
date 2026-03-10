---
name: touch-domain
description: Validate and scaffold a firehose domain's .context/ directory and required files without doing any content synthesis. Use to create or structurally check a domain.
disable-model-invocation: true
model: haiku
argument-hint: "[domain-path]"
---

You are implementing the **`/touch`** command from `orchestrator-architecture.md` as a Claude Code skill.

This skill is **structural only**:

- It ensures the domain's `.context/` directory and required files exist.
- It validates pointer integrity in `agent.md` if present.
- It may create minimal, spec-compliant scaffolding files.
- It **must not** perform any heavy content synthesis or regenerate `PROFILE.md`.

## How to interpret arguments

- If `$ARGUMENTS` is provided, treat `$0` as the **domain root path** (relative or absolute).
- If no arguments are provided, treat the **current working directory** as the domain root.

Always normalize to the domain root before operating.

## Steps

1. **Locate the domain root**
   - Resolve `$0` if present; otherwise use the current working directory.
   - Confirm that `README.md` exists at the domain root. If not present, create a minimal placeholder and note in comments that it should be human-authored.

2. **Ensure `.context/` layout**
   - Under the domain root, ensure a `.context/` directory exists.
   - Within `.context/`, ensure the following files and directories exist, creating minimal skeletons if needed:
     - `MEMORY.md`
     - `DECISIONS.md`
     - `STATE.md`
     - `PROFILE.md`
     - `agent.md`
     - `sessions/` directory (and `processed/` subdirectory inside it)
   - Skeleton contents should be as small as possible and clearly marked as placeholders that follow the structure described in `domain-convention.md`.

3. **Validate `agent.md` pointers**
   - If `agent.md` exists, read it and check any referenced context files (such as `MEMORY.md`, `DECISIONS.md`, `STATE.md`, or other listed paths) actually exist.
   - If a referenced file is missing, create an empty, clearly labeled placeholder consistent with the convention.

4. **Report structural health**
   - Summarize the results in chat and, optionally, in a small report file at:
     - `.context/TOUCH-REPORT.md`
   - The report should include:
     - Domain root path
     - Whether each required file existed or was created
     - Any pointer issues found and fixed in `agent.md`

5. **Do not regenerate PROFILE.md**
   - This skill **must not** rewrite `PROFILE.md` beyond creating a minimal placeholder if it was missing.
   - Regeneration of `PROFILE.md` belongs to the full-touch skill (`/touch-full-domain`), which performs content synthesis.

When unsure about the expected structure or file roles, read `domain-convention.md` in the repo root and follow its definitions.

