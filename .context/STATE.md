# State — domain-toolkit

## Current Status: Core skills implemented, distiller next

`/touch-domain` and `/open-kit` are implemented and tested. Registry is live with 7 domains. SessionStart hook is committed and installed. The remaining gap before daily use is the distillation pipeline.

## What's Done

- **Command taxonomy**: four commands, four concerns, cleanly separated
- **`/touch-domain` skill**: fully rewritten with modal modes (default, --full, --new, --all), git precheck (6 states), --no-touchy and -y modifiers. Reverted name from `touch` back to `touch-domain`.
- **`/open-kit` skill + shell script**: `bin/open-kit` script accepts `--cursor` (default) and `--terminal`. Skill wraps the same logic. Validates domain and workspace file before launching.
- **SessionStart hook**: committed, installed at `~/.claude/hooks/session-start.sh`, confirmed working. Injects context files on session start.
- **Domain registry**: `~/.claude/domain-toolkit/REGISTRY.md` (live, local) with 7 domains (4 with kits, 3 candidates). Template at `.claude/domain-toolkit/REGISTRY.example.md`.
- **Test domain**: `~/sources/touchy-muchy` bootstrapped via `/touch-domain --new` — validated the full onboarding flow
- **Spec updated**: `orchestrator-architecture.md` updated (`--full` without path → `--all` with cost warning)
- **PROFILE.md regenerated**: reflects current state of skills and hooks
- **agent.md updated**: skill references corrected (touch-domain)
- All prior work: specs, runtime verification, git setup, Cursor rules, README

## What's Blocked / Open

- **Distiller prompt not written** — `distiller-prompt.md` doesn't exist; headless distillation can't run yet
- **MEMORY.md is stale** — references Alacritty+tmux, says no README exists. Needs distillation or manual update.
- **Global config** (`~/.claude/domain-toolkit/config.md`) format not designed
- Session transcript capture: Claude Code native persistence vs `claudeProcessWrapper` — not decided
- `variety-agent-design.md` lives in cursus — decide whether to copy or reference
- LiteLLM gateway config details TBD

## Next Steps

1. Write distiller prompt (`distiller-prompt.md`) — enables headless `claude -p` distillation
2. Run distillation on stale MEMORY.md (or manual update as bootstrap)
3. Design global config format (`~/.claude/domain-toolkit/config.md`)
4. End-to-end test: full lifecycle through a real domain (not test)
5. Clean up touchy-muchy test domain

## Last Updated: 2026-03-10
