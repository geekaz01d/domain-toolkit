## Domain Understanding

The firehose repo is the **meta-repo** — it defines the orchestration system used to manage work across multiple domains. It contains specs (what the system should do) and Claude Code skills (how agents implement those behaviors). It is both the documentation and the implementation of its own conventions.

## Key Context

- **Architecture**: Two-tier — orchestrator (long-lived, holds registry) + subagents (ephemeral per-domain, communicate via filesystem)
- **Disk as shared bus**: Subagents never talk to each other in memory; `.context/` directories are the IPC layer
- **Spec files**: `orchestrator-architecture.md`, `domain-convention.md`, `distiller-spec.md` are the canonical references
- **Skills**: Implemented as Claude Code project-local skills under `.claude/skills/`
- **Runtime**: Alacritty + tmux, local user, no containers — `claude` CLI invocations for subagents

## Open Threads

- No README.md exists at domain root — placeholder needed
- `.context/` was just scaffolded for the first time (2026-03-09)
- Phase 1 (Minimal Viable Orchestrator) specs are complete; no implementation scripts exist yet
- `firehose/REGISTRY.example.md` exists but no live `firehose/REGISTRY.md` — not yet in active use

## Last Updated: 2026-03-09
