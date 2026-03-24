# add-domain: Register Single Domain

You are running `add-domain <path>` — register a single domain by reading its domain.yaml.

Read `domain-yaml-schema.md` for the domain.yaml schema.

## Steps

1. Verify `<path>/.claude/domain-toolkit/domain.yaml` exists. If not, error: "No domain.yaml found at `<path>`. Is this a managed domain? Use `add-domain --new <path>` to scaffold one."
2. Read and parse the domain.yaml file.
3. Read the current REGISTRY.yaml at `~/.claude/domain-toolkit/REGISTRY.yaml` (or create a new one if it doesn't exist). See `refs/registry-format.md` for the structure.
4. Add or update the domain entry under `domains:`:
   - Key: the `name` field from domain.yaml
   - `path`: the absolute path where domain.yaml was found. Apply `refs/path-normalization.md` rules.
   - Copy all fields from domain.yaml: `repo`, `type`, `description`, `sets`, `canonical_source`, `default_branch`, `remotes`, `kit_health`, `last_touched`, plus any freeform keys
   - If the domain already exists in the registry, merge: update all fields from domain.yaml, preserve any registry-only fields
5. Rebuild the sets index (computed reverse lookup from all domain `sets` fields).
6. Write REGISTRY.yaml with updated `generated` timestamp.
7. Report: "Registered `<name>` at `<path>` in REGISTRY.yaml."
