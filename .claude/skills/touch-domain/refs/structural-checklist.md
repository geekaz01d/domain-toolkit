# Structural Validation Checklist

Verify each of the following. For any missing element: if `--no-touchy` is active, just report it. Otherwise, create minimal placeholder scaffolding per `domain-convention.md`.

## Required files and directories

- `.context/` directory exists
- `.claude/domain-toolkit/domain.yaml` exists (detection signal, tracked in git)
- `persona.md` exists at domain root (agent identity, tracked in git)
- `CLAUDE.md` exists at domain root (domain governance, tracked in git). If missing, scaffold from `~/.claude/CLAUDE.md` (global default) with a comment noting it was auto-generated. If present, surface drift from the global default as a concern.
- Required `.context/` files exist: `STATE.md`, `MEMORY.md`, `DECISIONS.md`, `PROFILE.md`
- `.context/sessions/` directory exists
- `domain.code-workspace` exists at domain root

## Integrity checks

- Pointer integrity: if `persona.md` exists, check that any referenced files in its context map actually exist
- Access block: if domain.yaml contains an `access` section, validate its structure — `repos` entries must have `repo` (string) and `mode` (`rw` or `ro`); `mounts` entries must have `source`, `target`, and `mode`. Do NOT validate whether repos or mount paths are reachable — that's the deployment provider's job.

## PROFILE.md staleness heuristic

Compare PROFILE.md's modification time against MEMORY.md, DECISIONS.md, STATE.md, and README.md. If any source file is newer, PROFILE.md is considered stale. If stale, suggest `touch-domain --full` to regenerate.
