# touch-domain: Full Mode (`--full`)

You are running `touch-domain --full`. This does everything default mode does, **plus** content synthesis: PROFILE.md regeneration and workspace file generation.

Read `file-convention.md` for the file hierarchy and `set-assembly-spec.md` for the custodial checklist.

## Step 1: Git Precheck

Read `refs/git-precheck.md` and run the git precheck on the domain path. If the precheck blocks writes (Diverged or Behind), report the state and stop.

## Step 2: Structural Validation

Read `refs/structural-checklist.md` and run every check. Create scaffolding for any missing elements (unless `--no-touchy` -- read `refs/no-touchy.md` for behavior modifications).

## Step 3: Content Synthesis

1. Read canonical context files: `README.md`, `domain.yaml`, `persona.md`, `STATE.md`, `MEMORY.md`, `DECISIONS.md`
2. Perform a **light scan** of the domain's repo/folder contents:
   - Focus on key files referenced in the canonical context
   - Sample directory structure (don't exhaustively read large trees)

## Step 4: Regenerate PROFILE.md

Write `.context/PROFILE.md` with:
- Summary of what the domain is and does
- Key components, entry points, important files
- Important decisions and constraints from DECISIONS.md
- Current status and open threads from STATE.md
- Gaps or missing pieces in canonical files
- Header: `**Generated:** <date> (full touch)` and note that this is derived -- edit source files instead

## Step 5: Generate Workspace File

Generate or update `domain.code-workspace` at the domain root:
- Two folders: domain root + `.context/` (named "Domain Context")
- `folderOpen` task to open context files as tabs
- Extension recommendation for `anthropic.claude-code`

## Step 6: Report

Summarize results in chat:
- Domain root path and timestamp
- Git state (which of the 5 states, plus any concerns)
- What was validated, created, or regenerated
- Notable gaps or warnings
