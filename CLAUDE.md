# Domain Kit Engineering

This repo defines the domain kit architecture for managing durable human-agent collaboration across multiple domains.

## Design documents

Core specs (current):

- `docs/specs/command-taxonomy.md` – all commands, their concerns, and relationships
- `docs/specs/file-convention.md` – file hierarchy, load order, persona placement, AGENTS.md coexistence
- `docs/specs/domain-yaml-schema.md` – domain.yaml schema (detection signal, registry metadata)
- `docs/specs/domain-model-semantics.md` – domain types (subject, personal, operator), authorship vs operation lifecycle
- `docs/specs/registry-spec.md` – derived REGISTRY.yaml, scan paths, sets index, name resolution
- `docs/specs/set-assembly-spec.md` – git worktrees for set assembly, set roots, Docker integration, custodial checklist, agentic git operations, git recovery
- `docs/specs/storage-and-services.md` – storage topology, containerised viewports, Syncthing overlay
- `docs/specs/rename-spec.md` – rename identity model, scopes, execution order, boundaries
- `docs/specs/install-spec.md` – installation lifecycle, bundle manifest, hook chain, modes, preservation rules
- `docs/specs/distiller-spec.md` – distillation pipeline, first/second-order memory, isolation, strategies
- `docs/specs/sandbox-test-data.md` – demo sandbox specification

## Command taxonomy

| Command | Concern | Status |
|---------|---------|--------|
| **`touch-domain`** | Kit health — validation, git precheck, profile regen, scaffolding, bootstrapping | Implemented |
| **`open-domain`** | Viewport launch — single domain or set, Cursor/terminal/container | Implemented (single domain only) |
| **`add-domain`** | Registry management — scan, register, scaffold new domains | Implemented |
| **`group-domain`** | Set management — organise domains into named groups | Implemented |
| **`rename-domain`** | Domain identity — rename the logical name (label only, not storage) | Implemented |
| **`install-domain-toolkit`** | Runtime lifecycle — deploy, validate, or remove the runtime on a machine | Implemented |
| **`distill-domain`** | Memory processing — second-order re-synthesis from session transcripts | Pending (experimental) |
| **`overview`** | Capacity-aware briefing — registry scan filtered through personal domain | Implemented |

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
- **First-order memory:** session agents write STATE.md, MEMORY.md, and DECISIONS.md directly during interactive sessions. The distiller optionally re-synthesizes as a second-order pass.

## Claude Code skills for this repo

Multi-modal skills use a gate+phases pattern: SKILL.md classifies the mode, then loads the relevant phase file. See `skill-phase-decomposition-spec.md` for the design. `bin/lint-skills` validates skill structure.

- `/touch-domain` – domain management: structural validation, git precheck, profile regeneration, bootstrapping. Modal (decomposed: 4 phases + 3 refs).
- `/open-domain` – viewport launch: opens a domain in Cursor or terminal Claude session.
- `/add-domain` – registry management: scan, register, or scaffold new domains. Builds/updates REGISTRY.yaml. Modal (decomposed: 4 phases + 2 refs).
- `/distill-domain` – distillation: second-order re-synthesis of `MEMORY.md` / `DECISIONS.md` from session transcripts (experimental).
- `/group-domain` – set management: organise domains into named groups. Modifies domain.yaml sets fields.
- `/rename-domain` – domain identity: rename a domain's logical name (the `name` field in domain.yaml). Does not touch repo name, directory, bare repo, or remote URLs — storage reorganisation is a separate concern.
- `/install-domain-toolkit` – runtime lifecycle: deploy, validate, or remove the domain-toolkit runtime. Delegates to `bin/install-domain-toolkit` shell script.
- `/domain-convention` – agent posture for domain layout and file roles (not user-invocable).
- `/domain-overview` – capacity-aware briefing: registry scan filtered through personal domain profile.

## Workflow

1. `/touch-domain <path>` — validate or bootstrap a domain.
2. `/open-domain <domain> --cursor` — open the domain viewport for interactive work.
3. Optionally, run `/distill-domain <domain>` for second-order re-synthesis of `MEMORY.md` and `DECISIONS.md`.
