# Domain Toolkit Local Environment Config
#
# This file contains environment-specific settings for THIS installation
# of the domain-toolkit system. It is NOT part of the portable spec.
# Each domain-toolkit user would have their own version of this file.

## Git Remote Conventions

### Primary bare repo (origin)
- Host: root@fluffy.geekazoid.net
- Path pattern: /mnt/user/git/<repository>.git
- Example: root@fluffy.geekazoid.net:/mnt/user/git/domain-toolkit.git

### Secondary mirror (optional, per-domain opt-in)
- Provider: GitHub (private repos)
- Org/user: TBD

## Known Domains

### Touched (confirmed)
- domain-toolkit — this repo
- cashflow
- systems-architectures
- systems-geekazoid

### Candidates (not yet touched)
- systems-harrklen
- cursus.local
- claude-collect
- francoeur/agent-portfolio

## Desktop Environment
- OS: Linux Mint, MATE, X11
- Primary editor: Cursor (VS Code fork)
- Agent runtime: Claude Code CLI + Cursor extension
- Cowork (Claude desktop app) for spec work and design sessions

## Model Access
- Claude: via Claude Code CLI and Cursor extension (Anthropic direct)
- Other models: LiteLLM gateway to OpenRouter
  - Available for Cursor agent calls, comparison testing, and tasks where model diversity is useful
  - Configuration: TBD (endpoint, API key location)

## Notes
- fluffy.geekazoid.net is the primary server/NAS
- All bare repos live under /mnt/user/git/ on fluffy
- SSH access via root (key-based)
- `cursor` CLI is in PATH (not `code` — Cursor, not VS Code)
- Claude Code binary: ~/.local/share/claude/versions/ (compiled ELF, not npm)
