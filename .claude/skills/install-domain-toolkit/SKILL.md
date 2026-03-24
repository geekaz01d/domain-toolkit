---
name: install-domain-toolkit
description: "Installation lifecycle: deploy, link, validate, or remove the domain-toolkit runtime on this machine."
argument-hint: "[--status | --install | --link | --uninstall] [--cron]"
---

You are implementing the **`install-domain-toolkit`** command from `command-taxonomy.md`. This command manages the domain-toolkit runtime installation — the files, hooks, and settings that make the domain-toolkit system work on a machine.

Read `install-spec.md` for the full specification. The primary implementation is a shell script at `.claude/domain-toolkit/bin/install-domain-toolkit`. This skill delegates to that script.

## What This Command Does

Manages the machine-level runtime: deployed hooks, binaries, cron templates, hook wrappers, and settings.json registration. This is separate from domain-level management (which is `touch-domain`'s concern).

## Argument Parsing

If `$ARGUMENTS` is `--help`, `--usage`, or `-h`, print this usage summary and stop:

```
install-domain-toolkit — Runtime lifecycle management

Usage: /install-domain-toolkit [--status | --install | --link | --uninstall] [--cron]

Modes:
  --status      Read-only report of current installation state (default)
  --install     Full copy deployment to ~/.claude/domain-toolkit/
  --link        Symlink deployment (git pull updates runtime instantly)
  --uninstall   Clean removal, preserving user data

Modifiers:
  --cron        Manage crontab entries (opt-in, composable)
```

Parse `$ARGUMENTS` for mode flags:

- **`--status`** (default if no mode flag) — Read-only report of current installation state
- **`--install`** — Full copy deployment from the repo to `~/.claude/domain-toolkit/`
- **`--link`** — Symlink deployment (recommended for developers — `git pull` updates runtime instantly)
- **`--uninstall`** — Clean removal of runtime files, preserving user data (REGISTRY.yaml, logs)
- **`--cron`** — Opt-in modifier, composable with install/link/uninstall. Manages crontab entries.

## Execution

Locate the shell script at `.claude/domain-toolkit/bin/install-domain-toolkit` in the repo (not the installed copy). Run it with the appropriate flags:

```bash
bash .claude/domain-toolkit/bin/install-domain-toolkit $ARGUMENTS
```

The script handles:
1. Environment pre-checks (repo detection, python3, claude CLI, bundle integrity)
2. Mode dispatch (status, install, link, uninstall)
3. File operations (copy, symlink, remove)
4. settings.json JSON merge
5. Post-install validation
6. Always-ask confirmation before changes

## Interpreting Results

The script produces structured, human-readable output. Report it to the user as-is — the formatting is designed for direct consumption.

For `--status`, the output includes:
- Installation mode and timestamp
- Per-file status (current, outdated, missing, linked, dangling)
- Hook wrapper and registration state
- User data inventory
- Skills inventory
- Cron state
- Environment checks
- Overall verdict

## When to Suggest This Command

- User asks about setting up domain-toolkit on a new machine
- User asks if their installation is current or working
- User reports hooks not firing (suggest `--status` first)
- User wants to clean up domain-toolkit from their machine

## Relationship to Other Commands

- **Independent of `touch-domain`** — install manages the machine runtime, touch manages individual domains
- **Composes forward** — after install, suggest `add-domain` to register domains
- **Prerequisite for hooks** — hooks, transcript staging, and cron automation all require install
