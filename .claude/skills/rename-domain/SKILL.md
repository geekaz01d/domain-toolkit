---
name: rename-domain
description: "Domain identity: rename a domain's logical name. Updates domain.yaml name field and rebuilds the registry."
argument-hint: "<old-name> <new-name> [--no-touchy]"
---

You are implementing the **`rename-domain`** command from `command-taxonomy.md`. This renames a domain's logical identity — the `name` field in domain.yaml — and rebuilds the registry.

Read `rename-spec.md` for the full design rationale, identity model, and boundaries. Read `domain-yaml-schema.md` for the domain.yaml schema. Read `registry-spec.md` for registry format and name resolution.

## Scope

rename-domain changes the domain label. It does **not** touch the repo field, directory, bare repo, remote URLs, or any storage infrastructure. See `rename-spec.md` "Deferred: Storage Reorganisation" for why.

## Registry Location

`~/.claude/domain-toolkit/REGISTRY.yaml` — read this for name resolution and domain lookup.

## Argument Parsing

If `$ARGUMENTS` is `--help`, `--usage`, or `-h`, print this usage summary and stop:

```
rename-domain — Domain identity management

Usage: /rename-domain <old-name> <new-name> [--no-touchy]

Options:
  --no-touchy   Dry run — show the change plan without modifying anything
```

Parse `$ARGUMENTS` for flags and two positional arguments:

- **`<old-name> <new-name>`** — Rename the domain's logical name.
- **`<old-name> <new-name> --no-touchy`** — Dry run. Show what would change without modifying anything.

If fewer than two positional arguments are provided, error: "Usage: `rename-domain <old-name> <new-name> [--no-touchy]`"

## Pre-Flight Checks

Before doing anything, validate:

1. Read `~/.claude/domain-toolkit/REGISTRY.yaml`. If it doesn't exist, error: "No registry found. Run `add-domain --update` to build one."
2. Resolve `<old-name>` in the registry's `domains:` map. If not found, error: "Domain `<old-name>` not found in the registry."
3. Check that `<new-name>` does NOT already exist in the registry's `domains:` or `sets:` maps. If it does, error: "Name `<new-name>` is already in use (as a domain or set name)."
4. Get the domain's `path` from the registry entry. Expand `~` to `$HOME`.
5. Read `<path>/.claude/domain-toolkit/domain.yaml`. If it doesn't exist, error: "domain.yaml not found at the registered path. The registry may be stale — run `add-domain --update`."
6. If the domain path is a git repo, check for uncommitted changes. If dirty, error: "Working tree has uncommitted changes. Commit or stash before renaming." If not a git repo, skip this check.

## Present the Change Plan

Before executing, present a plan showing every change. This is mandatory — never skip it.

```
Rename plan:

  domain.yaml name:     <old-name> → <new-name>
  Registry:             re-keyed on rebuild

  Unchanged:
    repo:               <repo>
    directory:          <path>
    canonical_source:   <url>
    git remotes:        (unchanged)
```

If `--no-touchy`: display the plan and stop. "Dry run complete. No changes made."

If not `--no-touchy`: display the plan and ask: "Proceed with rename?"

## Situational Guidance

After presenting the plan, surface relevant context:

- If the directory basename already matches `<new-name>` (suggesting the user renamed the directory first): "It looks like you've already renamed the directory. This will update the domain name to match."
- If `<new-name>` differs from the current `repo` field: "After this rename, the domain name (`<new-name>`) and repo name (`<repo>`) will differ. The domain is fully workable in this state. `touch-domain` will surface the mismatch."

## Execution

1. **Update domain.yaml** — change `name` field to `<new-name>`. Preserve all other fields, comments, and formatting. Read the file, modify the specific field, write it back. Do not reorder fields.

2. **If git repo: commit** — `git -C <path> add .claude/domain-toolkit/domain.yaml && git -C <path> commit -m "Rename domain: <old-name> → <new-name>"`. If not a git repo, skip this step and note: "No git repo — change is not committed."

3. **Rebuild registry** — run the equivalent of `add-domain --update` to rebuild the full registry. The old name disappears and the new name appears because the registry is derived from domain.yaml files on disk.

4. **Report** — "Domain renamed: `<old-name>` → `<new-name>`. Registry updated."

If the commit step fails (git error), warn but continue to step 3 — domain.yaml is already updated and the registry should reflect it.

## What This Command Does NOT Do

- **Rename storage** — directory, bare repo, remote URLs, and `repo` field are untouched. This is a separate concern (see `rename-spec.md`).
- **Update prose references** — MEMORY.md, STATE.md, PROFILE.md, and session notes may reference the old name. These are not machine-updated.
- **Rename set names** — sets are independent identifiers managed by `group-domain`.

## Error Summary

- **Registry missing** — "No registry found. Run `add-domain --update` to build one."
- **Old name not found** — "Domain `<old-name>` not found in the registry."
- **New name already taken** — "Name `<new-name>` is already in use (as a domain or set name)."
- **domain.yaml missing at path** — "domain.yaml not found at the registered path. The registry may be stale."
- **Uncommitted changes (git only)** — "Working tree has uncommitted changes. Commit or stash before renaming."
- **Git commit failure** — Warn, continue with registry rebuild.
