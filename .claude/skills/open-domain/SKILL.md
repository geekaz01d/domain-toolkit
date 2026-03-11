---
name: open-domain
description: "Launch a domain viewport for interactive work. Opens a fresh, isolated Cursor window or terminal Claude session for the specified domain."
argument-hint: "<domain-path> [--cursor | --terminal]"
---

You are implementing the **`open-domain`** command from `orchestrator-architecture.md`. This command transitions from objective kit management to subjective interactive work inside a domain.

## Argument Parsing

Parse `$ARGUMENTS` for a domain identifier and a viewport flag:

- **`--cursor`** — Open in Cursor/VS Code (default if no flag given)
- **`--terminal`** — Open in terminal Claude Code (no IDE)
- The remaining non-flag argument is the **domain path or name**. Can be:
  - An absolute path (`~/sources/cashflow`)
  - A relative path (`../cashflow`)
  - A domain name that can be resolved via the registry (future — for now, require a path)
- If no domain is specified, list known domains from the registry (or prompt for a path if no registry exists).

Normalize to an absolute domain root path before proceeding.

## Prechecks

Before opening, validate:

1. **Domain exists**: The path must exist and contain `.claude/agent.md`. If not, tell the user: "Not a domain. Bootstrap it with `/touch-domain --new <path>`."
2. **Workspace file exists**: For `--cursor`, check that `<name>.code-workspace` exists at the domain root. If missing, tell the user: "No workspace file. Run `/touch-domain --full <path>` to generate one."

Do NOT run a full touch or fix problems — just check and report. The user decides what to do.

## `--cursor` Mode (default)

Open the domain in a fresh Cursor window.

1. Find the workspace file at the domain root (pattern: `*.code-workspace`)
2. Run via Bash:
   ```
   cursor --new-window <path-to-workspace-file>
   ```
3. Report to the user:
   - Domain name and path
   - Workspace file used
   - Remind them that the SessionStart hook will load context automatically when Claude Code starts in the new window

The workspace file handles everything else:
- Context files open as tabs (`folderOpen` task)
- Claude Code extension is recommended
- The SessionStart hook injects agent.md + PROFILE + MEMORY + DECISIONS + STATE

## `--terminal` Mode

Open the domain in a terminal Claude Code session (no IDE).

1. Run via Bash:
   ```
   claude --append-system-prompt-file <domain-path>/.claude/agent.md
   ```
   Use `--session-id` with a generated UUID for deterministic session tracking if desired.
2. Note: this launches Claude Code in the current terminal. The session inherits the domain's context via the system prompt file. The SessionStart hook will also fire and inject context files.

**Important:** Terminal mode launches an interactive `claude` process. This replaces the current session. Warn the user: "This will start a new Claude session in this terminal. Continue?"

## Report

After launching (or if blocked by a precheck), summarize:
- Domain: name and path
- Viewport: cursor or terminal
- Status: opened, or blocked (with reason and suggested fix)
