---
name: touch-domain
description: "Universal domain kit management: structural validation, git precheck, profile regeneration, or new domain bootstrapping. Modal — inspects state and picks the right action."
argument-hint: "[--full | --new | --all | --no-touchy | -y] [domain-path]"
---

You are implementing the **`touch-domain`** command from `command-taxonomy.md`.

## Argument Classification

Parse `$ARGUMENTS` for flags and a path. The remaining non-flag argument is the **domain path** (relative or absolute). If absent, use the current working directory. Normalize to an absolute path.

If `$ARGUMENTS` is `--help`, `--usage`, or `-h`, print this usage summary and stop:

```
touch-domain — Universal domain kit management

Usage: /touch-domain [--full | --new | --all | --no-touchy | -y] [domain-path]

Modes:
  (default)     Structural validation of a domain
  --full        Validation + PROFILE.md regeneration + workspace file
  --new         Interactive onboarding + scaffolding for a new domain
  --all         Sweep: run --full across every domain in the registry

Modifiers:
  --no-touchy   Read-only diagnostic (no writes, no prompts)
  -y            Auto-confirm safe git operations
```

Otherwise, identify which mode applies:

| Arguments | Mode | Phase file |
|-----------|------|------------|
| No mode flags | Default — structural validation | `phases/default.md` |
| `--full` | Full — validation + PROFILE.md regen | `phases/full.md` |
| `--new` | New — interactive onboarding + scaffolding | `phases/new.md` |
| `--all` | Sweep — full touch across registry | `phases/all.md` |

Modifier flags (`--no-touchy`, `-y`) are passed through to the phase — do not resolve them here.

Exception: `--new` with no path prompts for one. `--all` ignores the path and uses the registry.

**Read the identified phase file now and follow its instructions.** Do not proceed without reading the phase file.
