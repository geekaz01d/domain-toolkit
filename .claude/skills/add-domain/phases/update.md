# add-domain: Update Registry (`--update`)

You are running `add-domain --update` — walk all scan paths, re-scan domain.yaml files, rebuild the registry.

## Steps

1. Read `~/.claude/domain-toolkit/REGISTRY.yaml`. If it doesn't exist, error: "No registry found. Create one with `add-domain <path>` to register your first domain, or `add-domain --scan-path <path>` to set up scan paths."
2. Read the `scan_paths` list from REGISTRY.yaml.
3. Walk each scan path:
   - List immediate subdirectories (one level deep)
   - For each subdirectory, check if `.claude/domain-toolkit/domain.yaml` exists
   - If found, read and parse domain.yaml
   - Skip domains with `registry: exclude` in their domain.yaml
   - Do NOT recurse into subdirectories of found domains
4. For scan paths that are themselves domains (have domain.yaml at the scan path root), include them too.
5. Merge all found domains into the registry (see `refs/registry-format.md` for structure):
   - New domains are added
   - Existing domains are updated (all fields refreshed from domain.yaml)
   - Domains that were previously in the registry but not found on disk are **preserved with a flag**: add `on_disk: false` to their entry. Do not silently remove them — the user may have an unmounted drive or a domain on another machine.
6. Rebuild the sets index.
7. Write REGISTRY.yaml with updated `generated` timestamp. Apply `refs/path-normalization.md` rules to all paths.
8. Report summary: domains found, added, updated, not-found-on-disk. List any new domains or status changes.

## Error handling

- Parse errors in domain.yaml: report and skip, don't abort the whole scan
- Unreachable scan path: warn and continue with remaining paths
- Name collision (two domain.yaml files with the same `name`): report both paths, skip the duplicate, let the user resolve
