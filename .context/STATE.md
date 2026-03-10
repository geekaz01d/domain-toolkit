# State — firehose

## Current Status: Assumptions verified, ready to build

Repo is under git with bare on fluffy. Runtime assumptions verified (Claude Code CLI flags, Cursor CLI, SSH, workspace folderOpen tasks). Specs are stable. Next step is implementing skills in Cursor with Claude Code.

## What's Done

- **Command taxonomy**: four commands, four concerns, cleanly separated. Documented in orchestrator-architecture.md and README.md.
- **`touch-domain`** spec complete: default/--full/--new modes, --no-touchy and -y modifiers, git state precheck (6 states), extensible design
- **`open-kit`** spec complete: `--cursor` and `--terminal` viewport targets, workspace file launch
- **`checkpoint`** and **`distill`** specs carried forward from earlier work, aligned with new taxonomy
- **Variety-agent-design lineage**: domain kit as viable system (Ashby, Beer, VSM) integrated into README and DECISIONS
- Viewport pivot (2026-03-10): Cursor workspace-per-domain via `open-kit --cursor`
- Git conventions: agnostic spec with environment-specific settings in `firehose.local.md`
- All three spec documents revised and consistent
- README.md written with framing, user story, and command reference
- **Git initialized**: repo under git, bare repo on fluffy, origin configured
- **Runtime assumptions verified** (2026-03-10 Cowork session):
  - Claude Code CLI 2.1.72 with all required flags: --append-system-prompt-file, --system-prompt-file, --session-id, -p/--print
  - Cursor CLI in PATH with --new-window support
  - Workspace folderOpen tasks confirmed working
  - SSH to fluffy, bare repo infrastructure confirmed
  - `verify-assumptions.sh` captures all checks, re-runnable
- **Cursor rules**: `.cursor/rules/firehose.mdc` created for Cursor agent context
- **Local config updated**: `firehose.local.md` now documents Cursor as primary editor, LiteLLM gateway to OpenRouter, Claude Code binary location

## What's In Progress

- **Skill implementation**: existing skills (touch-domain, touch-full-domain) need update to match new spec (modal modes, git precheck)
- **`open-kit`** needs to be implemented as a skill or script

## What's Blocked / Open

- No live registry — identified 4 touched domains + ~4 candidates
- SessionStart hook: design complete, not implemented
- Session transcript capture: Claude Code native persistence vs `claudeProcessWrapper` — not decided
- Distiller prompt (`distiller-prompt.md`) not written
- Global config (`~/.firehose/config.md`) format not designed
- `variety-agent-design.md` lives in cursus, not in this repo — decide whether to copy or reference
- LiteLLM gateway config details (endpoint, key location) TBD

## Next Steps

1. Implement `touch-domain` skill with all modes (default, --full, --new, --no-touchy, -y, git precheck)
2. Implement `open-kit` as a skill (--cursor, --terminal)
3. Write `SessionStart` hook for automatic context loading
4. Write domain registry (REGISTRY.md)
5. Write distiller prompt
6. Design global config format
7. Test end-to-end: `touch-domain --new /path/to/test-domain` → onboarding → git → workspace → `open-kit test-domain --cursor`

## Last Updated: 2026-03-10
