---
name: open-domain
description: "Launch a domain viewport for interactive work. Opens a fresh, isolated session for the specified domain using named viewport profiles."
argument-hint: "<domain> [--viewport <name>]"
---

You are implementing the **`open-domain`** command from `command-taxonomy.md`. This command transitions from objective kit management to subjective interactive work inside a domain.

## Argument Classification

Parse `$ARGUMENTS` for a domain identifier and an optional `--viewport` flag.

If `$ARGUMENTS` is `--help`, `--usage`, or `-h`, print this usage summary and stop:

```
open-domain — Launch a domain viewport for interactive work

Usage: /open-domain <domain> [--viewport <name>]

Arguments:
  <domain>              Domain path (absolute or relative) or registry name

Options:
  --viewport <name>     Named viewport profile (e.g. tmux, cursor, screen, container)
  --terminal            Alias for --viewport terminal (backward compat)

Viewport resolution:
  1. Explicit --viewport argument
  2. default_viewport from ~/.claude/domain-toolkit/config.yaml
  3. terminal (bare launch in current shell)
```

Otherwise, identify which mode applies:

| Viewport resolved to | Mode | Phase file |
|----------------------|------|------------|
| `terminal` (or no viewport) | Terminal — bare launch in current shell | `phases/terminal.md` |
| Any named viewport | Profile — load YAML, evaluate conditions, execute | `phases/profile.md` |

**Backward compatibility:** `--terminal` is accepted as an alias for `--viewport terminal`. `--cursor` is retired — use `--viewport cursor`.

**Viewport resolution order:**
1. Explicit `--viewport <name>` argument (highest priority)
2. `default_viewport` from `~/.claude/domain-toolkit/config.yaml` (if file exists)
3. `terminal` (implicit default)

The remaining non-flag argument is the **domain path or name**. Can be an absolute path, a relative path, or a domain name resolvable via `~/.claude/domain-toolkit/REGISTRY.yaml`. If no domain is specified, list known domains from the registry (or prompt for a path if no registry exists). Normalize to an absolute domain root path.

**Read the identified phase file now and follow its instructions.** Do not proceed without reading the phase file.
