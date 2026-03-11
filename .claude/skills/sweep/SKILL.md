---
name: sweep
description: Coordinate a serial sweep across registered domains using the domain registry, guiding the user to work one domain at a time with checkpoints and distillation.
disable-model-invocation: true
model: haiku
argument-hint: "[optional-registry-path]"
---

You are implementing the **`/sweep`** command from `orchestrator-architecture.md` as a Claude Code skill.

This skill does **not** run all work automatically. Instead, it:

- Interprets and updates the **domain registry**.
- Chooses the next domain to work on.
- Guides the user through the standard viewport and session lifecycle for that domain.

## Registry format and location

1. By default, assume the registry is at:

   - `~/.claude/domain-toolkit/REGISTRY.md`

2. If `$ARGUMENTS` contains a path, treat `$0` as the registry file path instead.

3. The registry should be a human-readable markdown file, for example:

   ```markdown
   # Domain Registry

   | Domain | Path | Status | Last touched | Notes |
   |--------|------|--------|--------------|-------|
   | app-core | /path/to/app-core | pending | 2026-03-01 | Initial sweep not run |
   | billing | /path/to/billing | active | 2026-03-03 | In progress |
   | infra | /path/to/infra | complete | 2026-02-20 | |
   ```

4. If the registry file does not exist, create a minimal template and ask the user to populate it with a few domains before continuing.

## Status semantics

- `pending`: Domain has not yet been swept in the current sweep run.
- `active`: Domain currently being worked on.
- `complete`: Domain sweep finished for this run.
- `deferred`: Domain intentionally skipped for now.

You may add a separate "Sweep ID" section if the user wants multiple historical sweeps; for now, keep it simple.

## Sweep behavior

When the user invokes `/sweep`:

1. **Load the registry**
   - Read the registry file and parse the table of domains.

2. **Choose the next domain**
   - If any domain has `active` status, surface that domain and ask whether to:
     - Resume it.
     - Mark it deferred or complete.
   - Otherwise, select the next `pending` domain (by table order) as the new active domain.
   - If there are no `pending` or `active` domains, tell the user the sweep is complete.

3. **Update registry status**
   - Mark the chosen domain as `active`.
   - Ensure only one domain is marked `active` at a time.
   - Keep the registry in a clean, easy-to-read markdown table.

4. **Guide the user for the active domain**
   - Print a short briefing in chat:
     - Domain name and path.
     - Current registry status row.
   - Instruct the user to:
     - Open that domain in Claude Code (change directory).
     - Run `/touch-domain` followed by `/touch-full-domain` inside the domain if needed.
     - Use `/checkpoint` during the session, and `/checkpoint --close` at the end.
     - Optionally run `/distill-domain` afterwards to process the session.

5. **End-of-domain flow (informational)**
   - When the user indicates that work on the active domain is done, you should:
     - Mark the domain `complete` (or `deferred` if they explicitly want to skip it).
     - Clear the `active` status.
     - Suggest re-running `/sweep` to move to the next domain.

## What this skill does not do

- It does **not** automatically spawn subagents or run shell commands.
- It does **not** itself perform distillation or editing inside domains.
- It does **not** attempt to manage tmux layouts; that can be handled by external scripts if desired.

Instead, it acts as the **coordinator and status tracker** for a serial domain sweep, using the registry as the single source of truth and leaning on other skills (`/touch-domain`, `/touch-full-domain`, `/checkpoint`, `/distill-domain`) for per-domain work.

