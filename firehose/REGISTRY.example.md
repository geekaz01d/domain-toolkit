# Domain Registry (Template)

This is a template. Copy to `REGISTRY.md` (same directory) and populate with real domains.

The registry is the single source of truth for what domains the orchestrator knows about. It is the input to `/touch --all` and future `/firehose` sweeps.

## Format

Each domain gets one row. Columns:

| Column | Description |
|--------|-------------|
| **Domain** | Short name (directory basename or alias) |
| **Path** | Absolute path to domain root. Use `~` for home directory. |
| **Kit** | Whether `.context/` exists and is structurally valid: `yes`, `no`, or `partial` |
| **Last Touched** | Date of last `/touch` or `/touch --full` |
| **Notes** | Freeform — status, concerns, what this domain is |

## Registry

| Domain | Path | Kit | Last Touched | Notes |
|--------|------|-----|-------------|-------|
| example-project | ~/sources/example-project | yes | 2026-01-01 | Example entry |

## Conventions

- **Add domains** as you discover or create them. `/touch --new` should prompt to add.
- **Remove domains** by deleting the row. The domain files are unaffected.
- **Kit column** is updated by `/touch` — it reflects structural health at last check.
- **Last Touched** is updated by any `/touch` invocation.
- **This file is local** — it contains paths specific to this machine. Do not commit to shared repos. The template (`REGISTRY.example.md`) is the portable version.
