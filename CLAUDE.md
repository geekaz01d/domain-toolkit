# Domain Kit Engineering

This repo defines the domain kit architecture for managing durable human-agent collaboration across multiple domains. See `variety-agent-design.md` for the cybernetics-grounded theoretical foundation.

Key design documents:

- `orchestrator-architecture.md` – commands (`touch-domain`, `open-kit`, `checkpoint`, `distill`), viewport, runtime, hooks, git conventions.
- `domain-convention.md` – what a domain is, how `.context/` is structured, git convention, lifecycle.
- `distiller-spec.md` – how session artifacts become canonical `MEMORY.md` and `DECISIONS.md`.

## Command taxonomy

- **`touch-domain`** – kit management. Structural health, git state, profiling, scaffolding, bootstrapping. Objective.
- **`open-kit`** – viewport launch. Opens a domain for interactive work in a specified viewport (`--cursor`, `--terminal`).
- **`checkpoint`** – session capture. Structured snapshots during interactive work.
- **`distill`** – memory processing. Isolated post-session distillation. Objective, debiased.

## When working inside a domain kit

- Treat a **domain** as a folder with:
  - A root `README.md` describing what the domain is.
  - A `.context/` directory containing `PROFILE.md`, `MEMORY.md`, `DECISIONS.md`, `STATE.md`, `agent.md`, and `sessions/`.
- Follow the read/write flow from the specs:
  - **Read on entry:** `PROFILE.md → MEMORY.md → DECISIONS.md → STATE.md`.
  - **Write on exit:** use checkpoints and the distiller instead of editing memory/decisions directly.

## Claude Code skills for this repo

This project includes project-local skills under `.claude/skills/` that implement domain kit behavior:

- `/domain-convention` – reference for the domain layout and file roles.
- `/touch-domain` – structural validation and scaffolding for a domain's `.context/` directory.
- `/touch-full-domain` – full touch with PROFILE.md and workspace file generation.
- `/checkpoint` – writes structured session checkpoints and optional memory drafts into `.context/sessions/`.
- `/distill-domain` – runs the distillation pipeline for a single domain, producing `.proposed` updates.
- `/firehose` – (future) coordinates attention-direction sweep across domains.

## Workflow

1. `touch-domain <path>` — validate or bootstrap a domain.
2. `open-kit <domain> --cursor` — open the domain viewport for interactive work.
3. During work, use `/checkpoint` and `/checkpoint --close` to capture session artifacts.
4. After sessions, run `distill <domain>` to propose updates to `MEMORY.md` and `DECISIONS.md`.
