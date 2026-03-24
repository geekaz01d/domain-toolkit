# touch-domain: Default Mode

You are running `touch-domain` in **default mode** (no `--full`, `--new`, or `--all` flags). This is a smart touch -- inspect the target and pick the right action.

Read `file-convention.md` for the file hierarchy.

## Step 1: Git Precheck

Read `refs/git-precheck.md` and run the git precheck on the domain path. If the precheck blocks writes (Diverged or Behind), report the state and stop.

## Step 2: Inspect and Dispatch

Examine the target path and determine which case applies:

1. **Path doesn't exist or has no `.context/`**: Tell the user "This doesn't exist as a domain. Create it with `touch-domain --new <path>`." Do not create anything.

2. **Path exists, `.context/` exists but PROFILE.md is missing or stale**: Run structural validation (step 3). Suggest `touch-domain --full` to regenerate the profile.

3. **Path exists, `.context/` healthy**: Run structural validation only (step 3).

## Step 3: Structural Validation

Read `refs/structural-checklist.md` and run every check on the list.

If `--no-touchy` is set, read `refs/no-touchy.md` for behavior modifications -- report issues but do not create or modify anything.

## Step 4: Report

Summarize results in chat:
- Domain root path
- Git state (which of the 5 states, plus any concerns)
- What was found, created, or would be created (`--no-touchy`)
- Any warnings or suggestions for next steps
