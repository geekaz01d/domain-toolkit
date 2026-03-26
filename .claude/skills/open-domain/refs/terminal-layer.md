# Terminal Layer — Shared Reference

The terminal layer is the shared foundation for all viewports. Every viewport consumes its outputs — some ARE just this layer, others wrap it.

## Step 1: Resolve Domain

Resolve the domain identifier to an absolute domain root path:

1. If an absolute path — use as-is.
2. If a relative path — resolve against the current working directory.
3. If a name — look up in `~/.claude/domain-toolkit/REGISTRY.yaml` under the `path` field. Expand `~` to the user's home directory.
4. If no domain was specified — read the registry and list known domains for the user to choose from.

## Step 2: Prechecks

Validate before proceeding:

1. **Domain exists**: The resolved path must exist and contain `.claude/domain-toolkit/domain.yaml`. If not: "Not a domain. Bootstrap it with `/touch-domain --new <path>`." Stop.
2. **Read domain.yaml**: Extract the `name` field. This populates the `{name}` placeholder.

## Step 3: Build the Claude Launch String

Construct the launch command:

```
claude --append-system-prompt-file <domain-path>/persona.md
```

This string is available to viewport templates as the `{cmd}` placeholder. Additional flags (e.g. `--session-id`) may be appended if needed.

## Outputs

After running these steps, the following values are available:

| Value | Description |
|-------|-------------|
| `{name}` | Domain name from domain.yaml |
| `{path}` | Absolute domain root path |
| `{cmd}` | Claude launch string |
| `{workspace_file}` | Path to `*.code-workspace` at domain root (may not exist) |
