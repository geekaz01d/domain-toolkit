# General Computing & Troubleshooting Assistant

This directory serves as the home base for general computing tasks, system troubleshooting, and technical assistance.

## System Environment

- **OS**: Linux Mint 22.3 (Zena) based on Ubuntu Noble
- **Desktop Environment**: MATE with Marco window manager
- **Display Server**: X11
- **Hostname**: LAPPY1000
- **User**: richard
- **Shell**: bash
- **Scaling**: 2x HiDPI (window-scaling-factor=2)
- **First Order Tools**: Cursor IDE, Claude Code, Caja File Explorer
- **Second Order Tools**: Google Chrome, Guake Terminal, Obsidian

## Primary Use Cases

This workspace is an entry point to context-specific Claude sessions. See Context Language Boot Sequence

When working within this directory, focus on:

1. **General Computing Help**
   - System configuration and customization
   - Application troubleshooting
   - File management and organization
   - Performance optimization

2. **Troubleshooting & Diagnostics**
   - System issues and error messages
   - Hardware detection and driver problems
   - Network connectivity issues
   - Software conflicts and dependencies

3. **System Administration**
   - Package management (apt, dpkg)
   - Service management (systemd)
   - User and permission management
   - System monitoring and logs

4. **Desktop Environment Customization**
   - MATE/Marco configuration
   - Keybindings and shortcuts
   - Themes and appearance
   - Panel and workspace setup

5. **Learning & Exploration**
   - Understanding Linux commands and tools
   - Exploring system capabilities
   - Discovering new utilities and features

## Approach

- **Investigate before acting**: When troubleshooting, gather information first
- **Explain what you're doing**: Help me learn while you solve problems
- **Non-destructive by default**: Always ask before making system-wide changes
- **Preserve existing setup**: Don't change settings without checking current state
- **Check logs and diagnostics**: Use system logs, dmesg, journalctl when investigating issues

---

## Context Language Boot Sequence

On every session start, run these steps in order before doing anything else:

1. Read `~/.claude/current-context` — this is your Name for this session. If absent or empty, you are in the default general computing context above.

2. Read `~/.claude/names` — the full registry of available contexts and skills. Keep this available for resolving verb commands.

3. If context is not "home" and not empty:
   - Read `.claude/MEMORY.md` in the current directory if present — persistent learnings from prior sessions
   - Read `.claude/STATE.md` in the current directory if present — where we left off

4. Read `~/.claude/current-skills` — if non-empty, read each named skill file from `~/.claude/skills/<name>.md` and apply its posture

5. Read `~/.claude/current-flags` — if non-empty, apply any session modifiers

## Context Language Verbs

These commands are available in every session:

| Verb | Syntax | Behavior |
|---|---|---|
| `start` | `start <name> [and <name>] [as <alias>]` | New Guake tab, fresh Claude session |
| `switch` | `switch <name>` | Restart current session with new context |
| `include` | `include <name>` | Add context to current scope |
| `exclude` | `exclude <name>` | Remove context from current scope |
| `close` | `close` | Save STATE.md and exit cleanly |
| `forget` | `forget` | Exit without saving |
| `preview` | `preview <expression>` | Dry-run: show cost estimate, confirm before executing |

**`and`** — compose multiple names: `start systems-geekazoid and systems-architectures`
**`as`** — name a composition: `start a and b as my-alias` (makes it canonical)
**`all`** — expand to all names of a type: `all`, `all contexts`, `all skills`

## Gap Capture

To capture a missing capability to the current context's backlog:

```
/gap [context-name] description
```

Context name inferred from `~/.claude/current-context` if omitted. Appends to `.claude/backlog.md` in the resolved context path.
