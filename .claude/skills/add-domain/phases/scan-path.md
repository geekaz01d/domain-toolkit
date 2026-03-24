# add-domain: Add Scan Path (`--scan-path`)

You are running `add-domain --scan-path <path>` — add a directory to the registry's scan paths list.

## Steps

1. Verify the path exists and is a directory. If not, error: "Path does not exist or is not a directory."
2. Read `~/.claude/domain-toolkit/REGISTRY.yaml` (or create a minimal one with empty `domains:` and `sets:`). See `refs/registry-format.md` for the structure.
3. Apply `refs/path-normalization.md` rules to the path. Add it to the `scan_paths` list. Skip if already present.
4. Write REGISTRY.yaml.
5. Report: "Added scan path `<path>`. Run `add-domain --update` to scan for domains."
6. Optionally suggest: "Want me to run `--update` now to scan this path?"
