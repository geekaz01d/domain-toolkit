---
name: group-domain
description: "Set management: organise domains into named groups. Modifies domain.yaml sets fields and rebuilds the registry."
argument-hint: "<set-name> [--add <domain> | --remove <domain>] | --list"
---

You are implementing the **`group-domain`** command from `command-taxonomy.md`. This manages set membership — organising domains into named groups.

Read `registry-spec.md` for the sets index and name resolution. Read `domain-yaml-schema.md` for the `sets` field in domain.yaml.

## Core Principle

**The source of truth for set membership is each domain's `domain.yaml` `sets:` field.** The registry's `sets:` index is a computed reverse lookup derived from those fields. To change set membership, you modify domain.yaml files, then rebuild the registry.

## Registry Location

`~/.claude/domain-toolkit/REGISTRY.yaml` — read this for domain lookups, set listings, and name resolution.

## Argument Parsing

Parse `$ARGUMENTS` for flags, a set name, and a domain name:

- **`<set-name> --add <domain-name>`** — Add the named domain to the named set
- **`<set-name> --remove <domain-name>`** — Remove the named domain from the named set
- **`<set-name>`** (no flags) — List all domains in the named set
- **`--list`** (no set name) — List all sets and their members

If both `--add` and `--remove` are present, error: "Specify either --add or --remove, not both."

## Mode: Add Domain to Set

`group-domain <set> --add <domain>`

1. Read `~/.claude/domain-toolkit/REGISTRY.yaml`. If it doesn't exist, error: "No registry found. Run `add-domain --update` to build one."
2. Resolve `<domain>` in the registry's `domains:` map. If not found, error: "Domain `<domain>` not found in the registry. Check the name or register it with `add-domain <path>`."
3. Get the domain's `path` from the registry entry. Expand `~` to `$HOME`.
4. Read `<path>/.claude/domain-toolkit/domain.yaml`. If it doesn't exist, error: "domain.yaml not found at `<path>`. The registry may be stale — run `add-domain --update`."
5. Parse the `sets:` field from domain.yaml. If `<set>` is already in the list, report: "`<domain>` is already a member of set `<set>`. No changes made." and stop.
6. Append `<set>` to the `sets:` list. Preserve all other fields, comments, and formatting.
7. Write the updated domain.yaml back to disk.
8. Commit the change: `git -C <path> add .claude/domain-toolkit/domain.yaml && git -C <path> commit -m "Add to set: <set>"`. If the commit fails, warn but continue.
9. Run `add-domain --update` to rebuild the registry with the updated sets index.
10. Report: "Added `<domain>` to set `<set>`. Registry updated."

## Mode: Remove Domain from Set

`group-domain <set> --remove <domain>`

1. Read `~/.claude/domain-toolkit/REGISTRY.yaml`. If it doesn't exist, error as above.
2. Resolve `<domain>` in the registry's `domains:` map. If not found, error as above.
3. Get the domain's `path` from the registry entry. Expand `~` to `$HOME`.
4. Read `<path>/.claude/domain-toolkit/domain.yaml`. If it doesn't exist, error as above.
5. Parse the `sets:` field from domain.yaml. If `<set>` is NOT in the list, report: "`<domain>` is not a member of set `<set>`. No changes made." and stop.
6. Remove `<set>` from the `sets:` list. If the list becomes empty, keep `sets:` as an empty list (`sets: []`) — do not remove the key.
7. Write the updated domain.yaml back to disk.
8. Commit the change: `git -C <path> add .claude/domain-toolkit/domain.yaml && git -C <path> commit -m "Remove from set: <set>"`. Warn on failure but continue.
9. Run `add-domain --update` to rebuild the registry.
10. Report: "Removed `<domain>` from set `<set>`. Registry updated."
11. If the set has no remaining members after the registry rebuild, note: "Set `<set>` is now empty and will not appear in the registry."

## Mode: List Set Members

`group-domain <set>`

1. Read `~/.claude/domain-toolkit/REGISTRY.yaml`. If it doesn't exist, error as above.
2. Look up `<set>` in the `sets:` index. If the set doesn't exist, report: "No set named `<set>` found. Use `group-domain --list` to see all sets."
3. For each domain name in the set's member list, read its entry from `domains:` to get description, type, and last_touched.
4. Display a formatted list:

```
Set: infrastructure (3 domains)

  systems-geekazoid       ~/sources/infrastructure/systems-geekazoid       last touched: 2026-03-19
  systems-harrklen        ~/sources/infrastructure/systems-harrklen        last touched: 2026-03-19
  systems-architectures   ~/sources/infrastructure/systems-architectures   last touched: 2026-03-19
```

## Mode: List All Sets

`group-domain --list`

1. Read `~/.claude/domain-toolkit/REGISTRY.yaml`. If it doesn't exist, error as above.
2. Read the `sets:` index. If empty, report: "No sets defined. Add domains to sets with `group-domain <set-name> --add <domain>`."
3. Display all sets sorted alphabetically, with member counts and domain names:

```
Sets (6):

  francoeur        (1)  agent-portfolio
  geekazoid        (2)  cashflow, systems-geekazoid
  infrastructure   (3)  systems-geekazoid, systems-harrklen, systems-architectures
  meta             (1)  domain-toolkit
  money            (1)  cashflow
  personal         (1)  cursus
```

## Writing domain.yaml Safely

When modifying domain.yaml:

- **Read the entire file, modify the `sets:` field, write the entire file back.** Do not use sed or partial writes.
- **Preserve all existing fields, comments, and formatting** as much as possible. The `sets:` field is a YAML list under a known key — update only that list.
- **Preserve field ordering.** domain.yaml has a conventional section order (user-declared, git recovery context, derived, freeform). Do not reorder fields.
- If the `sets:` key doesn't exist in domain.yaml, add it in the user-declared section (after `description`).

## Error Handling

- **Registry missing** — "No registry found. Run `add-domain --update` to build one."
- **Domain not in registry** — "Domain `<name>` not found in the registry." Suggest checking the name or registering the domain.
- **domain.yaml missing at registered path** — "domain.yaml not found at the registered path. The registry may be stale — run `add-domain --update`."
- **Already a member** (for --add) — Report and stop cleanly, no error.
- **Not a member** (for --remove) — Report and stop cleanly, no error.
- **Git commit fails** — Warn that the domain.yaml was updated but the change was not committed. Suggest manual commit.
