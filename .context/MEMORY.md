## Domain Understanding

The domain-toolkit repo is the **meta-repo** — it defines the orchestration system used to manage work across multiple domains. It contains specs (what the system should do) and Claude Code skills (how agents implement those behaviors). It is both the documentation and the implementation of its own conventions.

The core concept is the **domain kit**: the complete set of domain-specific resources an agent is given access to — prompts, personas, context, state, memories, tools, skills — plus a session-distillation loop. Grounded in cybernetics (Ashby's Law, Beer's VSM).

## Key Context

- **Architecture**: Two-tier — orchestrator (long-lived, holds registry) + subagents (ephemeral per-domain, communicate via filesystem)
- **Disk as shared bus**: `.context/` directories are the IPC layer. Everything is interruptible and resumable.
- **Spec files**: `orchestrator-architecture.md`, `domain-convention.md`, `distiller-spec.md` are the canonical references
- **Skills**: Implemented as Claude Code project-local skills under `.claude/skills/` — `touch-domain`, `open-kit`, `checkpoint`, `distill-domain`, `domain-convention`
- **Runtime**: Cursor IDE (primary viewport), Claude Code CLI, VS Code workspace-per-domain. `open-kit --cursor` launches isolated domain windows.
- **Context loading**: SessionStart hook (`hooks/session-start.sh`) injects context files deterministically on entry. Installed globally.
- **Distillation**: Headless `claude -p` with `--system-prompt-file` — isolated, debiased by disk boundary.
- **Registry**: `~/.claude/domain-toolkit/REGISTRY.md` (live, local) with 7 domains (4 with kits, 3 candidates).

## Command Taxonomy

| Command | Concern | Status |
|---------|---------|--------|
| `touch-domain` | Kit management (validate, scaffold, profile, bootstrap, git precheck) | Implemented |
| `open-kit` | Viewport launch (`--cursor`, `--terminal`) | Implemented |
| `checkpoint` | Session capture | Stable |
| `distill` | Post-session memory processing (isolated) | Skill exists, distiller prompt not written |
| `sweep` | Cross-domain attention sweep | Future |

## Open Threads

- Distiller prompt (`distiller-prompt.md`) not written — blocks headless distillation
- Global config (`~/.claude/domain-toolkit/config.md`) format not designed
- Session transcript capture approach undecided (Claude Code native vs `claudeProcessWrapper`)
- `variety-agent-design.md` lives in cursus — decide whether to copy or reference
- LiteLLM gateway config details TBD
- `touchy-muchy` test domain should be cleaned up

## Last Updated: 2026-03-10
