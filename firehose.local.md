# Firehose Local Environment Config
#
# This file contains environment-specific settings for THIS installation
# of the firehose system. It is NOT part of the portable spec.
# Each firehose user would have their own version of this file.

## Git Remote Conventions

### Primary bare repo (origin)
- Host: root@fluffy.geekazoid.net
- Path pattern: /mnt/user/git/<repository>.git
- Example: root@fluffy.geekazoid.net:/mnt/user/git/firehose.git

### Secondary mirror (optional, per-domain opt-in)
- Provider: GitHub (private repos)
- Org/user: TBD

## Known Domains

### Touched (confirmed)
- firehose — this repo
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
- Editor: VS Code / Cursor
- Agent runtime: Claude Code CLI + VS Code extension

## Notes
- fluffy.geekazoid.net is the primary server/NAS
- All bare repos live under /mnt/user/git/ on fluffy
- SSH access via root (key-based)
