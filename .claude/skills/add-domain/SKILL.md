---
name: add-domain
description: "Registry management: scan, register, or scaffold new domains. Reads domain.yaml files from disk and builds/updates REGISTRY.yaml."
argument-hint: "[--update | --new | --scan-path] [path]"
---

You are implementing the **`add-domain`** command from `command-taxonomy.md`.

Registry location: `~/.claude/domain-toolkit/REGISTRY.yaml`

## Argument Classification

Parse `$ARGUMENTS` for flags and a path. Normalize paths to absolute. Expand `~` to the user's home directory.

If `$ARGUMENTS` is `--help`, `--usage`, or `-h`, print this usage summary and stop:

```
add-domain — Registry management

Usage: /add-domain [--update | --new | --scan-path] [path]

Modes:
  <path>              Register a single domain by reading its domain.yaml
  --update            Walk all scan paths, rebuild the registry
  --new <path>        Scaffold a new domain and register it
  --scan-path <path>  Add a directory to the scan paths list
```

Otherwise, identify which mode applies:

| Arguments | Mode | Phase file |
|-----------|------|------------|
| `<path>` (no flags) | Register single domain | `phases/register.md` |
| `--update` | Rebuild registry from scan paths | `phases/update.md` |
| `--new <path>` | Scaffold + register | `phases/new.md` |
| `--scan-path <path>` | Add scan path | `phases/scan-path.md` |

**Read the identified phase file now and follow its instructions.** Do not proceed without reading the phase file.
