# Domain Kit Engineering

This repo defines the domain kit architecture for managing durable human-agent collaboration across multiple domains.

## Design documents

Core specs (current):

- `docs/specs/command-taxonomy.md` – all commands, their concerns, and relationships
- `docs/specs/file-convention.md` – file hierarchy, load order, persona placement, AGENTS.md coexistence
- `docs/specs/domain-yaml-schema.md` – domain.yaml schema (detection signal, registry metadata)
- `docs/specs/domain-model-semantics.md` – domain types (subject, personal, operator), authorship vs operation lifecycle
- `docs/specs/registry-spec.md` – derived REGISTRY.yaml, scan paths, sets index, name resolution
- `docs/specs/git-operations.md` – three-tier disposability, sync model, custodial checklist, agentic git operations
- `docs/specs/set-assembly-spec.md` – git worktrees for set assembly, set roots, Docker integration
- `docs/specs/storage-and-services.md` – storage topology, containerised viewports, Syncthing overlay
- `docs/specs/distiller-spec.md` – distillation pipeline, isolation requirement, strategies, review gate

Foundational specs (partially superseded — see notices in each file):

- `docs/specs/orchestrator-architecture.md` – original architecture. Domain kit concept, concurrency, persistence.
- `docs/specs/domain-convention.md` – original convention. Session files, MEMORY/DECISIONS structure.

## Command taxonomy

| Command | Concern | Status |
|---------|---------|--------|
| **`touch-domain`** | Kit health — validation, git precheck, profile regen, scaffolding, bootstrapping | Implemented |
| **`open-domain`** | Viewport launch — single domain or set, Cursor/terminal/container | Implemented (single domain only) |
| **`add-domain`** | Registry management — scan, register, scaffold new domains | Implemented |
| **`group-domain`** | Set management — organise domains into named groups | Not yet implemented |
| **`rename-domain`** | Domain identity — rename safely across all references | Not yet implemented |
| **`distill-domain`** | Memory processing — isolated post-session distillation | Pending (distiller prompt not written) |
| **`overview`** | Capacity-aware briefing — registry scan filtered through personal domain | Not yet implemented |

## When working inside a domain kit

- Treat a **domain** as a folder with:
  - A root `README.md` describing what the domain is.
  - `.claude/domain-toolkit/domain.yaml` — machine-readable manifest, detection signal (tracked in git).
  - `persona.md` — context-specific agent identity, context map, behavioural settings (tracked in git).
  - A `.context/` directory containing `PROFILE.md`, `MEMORY.md`, `DECISIONS.md`, `STATE.md`, and `sessions/` (gitignored, synced via Syncthing).
- Follow the load order from `file-convention.md`:
  1. Global governance (`~/AGENTS.md`, `~/.claude/CLAUDE.md`)
  2. Domain governance (`<domain>/CLAUDE.md`, `AGENTS.md` if present)
  3. Persona (closest `persona.md` to launch context)
  4. Context files (`PROFILE.md → MEMORY.md → DECISIONS.md → STATE.md`)
- **Write on exit:** use the distiller instead of editing memory/decisions directly.

## Claude Code skills for this repo

- `/touch-domain` – domain management: structural validation, git precheck, profile regeneration, bootstrapping. Modal.
- `/open-domain` – viewport launch: opens a domain in Cursor or terminal Claude session.
- `/add-domain` – registry management: scan, register, or scaffold new domains. Builds/updates REGISTRY.yaml.
- `/distill-domain` – distillation: transforms session artifacts into proposed `MEMORY.md` / `DECISIONS.md` updates.
- `/domain-convention` – agent posture for domain layout and file roles (not user-invocable).
- `/domain-overview` – cross-domain attention overview (not yet implemented).

## Workflow

1. `/touch-domain <path>` — validate or bootstrap a domain.
2. `/open-domain <domain> --cursor` — open the domain viewport for interactive work.
3. After sessions, run `/distill-domain <domain>` to propose updates to `MEMORY.md` and `DECISIONS.md`.
