# touch-domain: All Mode (`--all`)

You are running `touch-domain --all`. This sweeps the entire domain registry with `--full` touch on each domain. **Expensive** -- requires a model call per domain.

Read `registry-spec.md` for the registry format.

## Step 1: Load Registry

Read `~/.claude/domain-toolkit/REGISTRY.yaml` to get the list of known domains.

If no registry exists, tell the user: "No registry found. Create one with `add-domain --update` or seed `REGISTRY.yaml`." Stop.

## Step 2: Cost Warning

Count the domains and **always warn**: "This will run a full touch on N domains (model call per domain). Proceed?"

This prompt is **never suppressed** -- not by `-y`, not by automation. The user must confirm.

## Step 3: Sweep

If confirmed, iterate through each domain and run the `--full` protocol on it:
1. Read `refs/git-precheck.md` and run the git precheck
2. Read `refs/structural-checklist.md` and run structural validation
3. Run content synthesis, PROFILE.md regeneration, and workspace generation

If `--no-touchy` is set (read `refs/no-touchy.md`), do a dry-run sweep: report what each domain's full touch would find, but write nothing.

## Step 4: Summary

Summarize the sweep:
- Number of domains touched
- Issues found per domain
- Profiles regenerated
- Any domains that were skipped (git state blocking, unreachable paths)
