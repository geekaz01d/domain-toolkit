# Domain Toolkit Local Environment Config
#
# This file contains environment-specific settings for THIS installation
# of the domain-toolkit system. It is NOT part of the portable spec.
# Each domain-toolkit user would have their own version of this file.
#
# Copy this to ~/.claude/domain-toolkit/domain-toolkit.local.md and
# fill in your details.

## Git Remote Conventions

### Primary bare repo (origin)
- Host: user@yourserver.example.com
- Path pattern: /path/to/git/<repository>.git
- Example: user@yourserver.example.com:/path/to/git/my-project.git

### Secondary mirror (optional, per-domain opt-in)
- Provider: GitHub (private repos)
- Org/user: your-github-username

## Known Domains

### Touched (confirmed)
- domain-toolkit — this repo
- my-project
- another-project

### Candidates (not yet touched)
- idea-i-havent-started
- client-work

## Desktop Environment
- OS: (your OS)
- Primary editor: Cursor / VS Code
- Agent runtime: Claude Code CLI + editor extension

## Model Access
- Claude: via Claude Code CLI and editor extension (Anthropic direct)
- Other models: (optional — LiteLLM, OpenRouter, local models, etc.)

## Notes
- Add any environment-specific details here: server names, SSH config,
  CLI tool locations, workarounds, etc.
