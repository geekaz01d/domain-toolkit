# Decisions — firehose

## 2026-03-09: Disk as shared bus (no in-memory subagent communication)
- **Context**: Designing subagent communication model for the orchestrator
- **Alternatives considered**: In-memory message passing, shared state object, RPC
- **Deciding factors**: Interruptibility and resumability by design; any process can crash and resume from last checkpoint; clean context isolation between domains
- **Revisit if**: Performance bottleneck from filesystem I/O becomes significant, or if real-time coordination between subagents is needed

## 2026-03-09: Serial firehose sweep (not parallel)
- **Context**: How to structure domain sweeps in `/firehose`
- **Alternatives considered**: Parallel domain processing
- **Deciding factors**: Full human attention per domain; interactive review phase requires focus; parallelism available for `/touch --full` where no interaction needed
- **Revisit if**: Volume of domains makes serial sweeps impractical

## 2026-03-09: Skills over scripts (Claude Code project-local skills)
- **Context**: Implementation approach for orchestrator commands
- **Alternatives considered**: Shell scripts, Python scripts, standalone CLI tool
- **Deciding factors**: Skills run in the same Claude Code session, no separate process management; skills can use all Claude Code tools; easier iteration
- **Revisit if**: Skills become too complex for inline implementation; need persistent background processes

## 2026-03-09: Staged writes — agents never write to canonical files directly
- **Context**: Memory and decision integrity across sessions
- **Alternatives considered**: Direct agent writes to MEMORY.md/DECISIONS.md
- **Deciding factors**: Human review gate ensures accuracy; distiller pipeline allows conflict detection; accidental overwrite risk too high
- **Revisit if**: Auto-approve mode becomes trusted enough for low-stakes domains

## 2026-03-09: Window-per-domain tmux model
- **Context**: UI layout for firehose sessions
- **Alternatives considered**: Pane reuse, single-window with content swap
- **Deciding factors**: tmux tab bar becomes sweep history; no fragile pane reuse; completed domains visible as tabs; natural navigation
- **Revisit if**: Tab bar becomes cluttered with many domains
- **Status**: SUPERSEDED by 2026-03-10 decision below

## 2026-03-10: VS Code workspace-per-domain viewport (replaces tmux/neovim)
- **Context**: Revisiting the viewport layer. Neovim/LazyVim + tmux required a Lua orchestrator module, tmux automation scripts, and shell wrappers — significant custom glue. Explored Cowork as an alternative; it lacks programmatic session creation and multi-file viewport. Discovered Claude Code's CLI flags (`--add-dir`, `--append-system-prompt-file`, `--session-id`) and VS Code workspace features (`folderOpen` tasks, `code` CLI for tab management) provide the viewport natively.
- **Alternatives considered**: Neovim + tmux (original), Cowork sessions, Cursor IDE
- **Deciding factors**: VS Code workspace files auto-open context files as tabs, launch Claude Code via `folderOpen` task, and support markdown preview — no custom code needed. The `code --new-window domain.code-workspace` command is the single entry point. Eliminates Phase 1 and Phase 2 glue code entirely. Agent can surface files mid-session via `code <file>` through Bash.
- **Revisit if**: VS Code `code` CLI becomes unreliable from within the integrated terminal; need for cross-domain visibility within a single viewport; VS Code performance degrades with many domain windows open

## 2026-03-10: Claude Code hooks for automatic context loading
- **Context**: Need the read-on-entry flow (PROFILE → MEMORY → DECISIONS → STATE) to happen automatically, not via prompt instruction
- **Alternatives considered**: Manual prompt ("read my context files"), CLAUDE.md instruction, skill-based loading
- **Deciding factors**: SessionStart hooks are deterministic — guaranteed to execute, not LLM-dependent. Hook stdout is injected directly as context. Fast, reliable, no wasted tokens on tool calls.
- **Revisit if**: Hook output size limits become a problem for large MEMORY.md files; SessionStart hook reliability issues (known bug with new conversations as of early 2026)

## 2026-03-10: Headless `claude -p` for distillation (isolated context)
- **Context**: Distiller must run without the working session's conversation history to avoid completion bias
- **Alternatives considered**: Cowork subagent, in-session distillation, separate API call
- **Deciding factors**: `claude -p` with `--system-prompt-file` gives a clean invocation with no shared context. Same tooling as interactive sessions (skills, filesystem access). The disk boundary between working agent and distiller is a debiasing mechanism, not just an implementation convenience.
- **Revisit if**: Claude Code provides a native "isolated subagent" primitive that's cleaner than `claude -p`

## 2026-03-10: Agent teams NOT used for cross-domain orchestration
- **Context**: Evaluated Claude Code agent teams (experimental) for firehose sweep coordination
- **Alternatives considered**: Agent team lead coordinates domain teammates
- **Deciding factors**: Agent teams share a working directory and task list — designed for multiple agents on ONE problem, not isolation between domains. Messaging system would allow domain context leakage. Agent teams are appropriate within a single domain (e.g., parallel research) but not as the firehose sweep mechanism.
- **Revisit if**: Agent teams gain per-teammate working directory isolation

## 2026-03-10: touch-domain as universal modal command
- **Context**: Touch was a health check. New requirement: touch should also be the entry point for domain creation. When you touch a path that doesn't exist, it should bootstrap a new domain. The bootstrapping conversation itself becomes the first session artifact.
- **Alternatives considered**: Separate `create-domain` command, manual scaffolding then touch
- **Deciding factors**: One command to rule them all. `touch-domain` inspects state and picks the right action: light validation, full profile regen, or new domain onboarding. Explicit flags (`--full`, `--new`) for when you want to force a mode. Default is smart — prompts for escalation when conditions warrant. Designed for extensibility: more `--options` will emerge.
- **Revisit if**: The modal behavior becomes confusing or unpredictable; flags proliferate beyond usability

## 2026-03-10: Git-aware domains with standard remote conventions
- **Context**: Domains should be version-controlled by default. Git provides an audit trail for agentic changes, ensures work is not lost, and enables the bare-repo-on-server convention Richard uses across projects.
- **Alternatives considered**: No git integration (leave it to the user), per-domain opt-in only
- **Deciding factors**: Git is assumed for all domains unless explicitly exempted. Global defaults define the standard setup (bare repo on configured primary server, optional secondary mirror). Per-domain overrides in agent.md. Touch checks git status as part of housekeeping — surfaces concerns, doesn't silently fix. `touch-domain --new` initializes git as part of bootstrapping. Environment-specific settings (server hostnames, paths) live in `firehose.local.md`, not in the portable spec.
- **Revisit if**: Domains emerge that genuinely shouldn't be git repos (ephemeral scratch domains?); bare repo convention becomes impractical for some repo types

## 2026-03-10: Command taxonomy — four concerns, four commands
- **Context**: Clarifying the command structure as the system scope expanded beyond the original "firehose" sweep concept. Need clean separation between kit management, viewport launching, session capture, and memory processing.
- **Alternatives considered**: Everything under `/firehose` umbrella, separate commands per function with inconsistent naming
- **Deciding factors**: Each command maps to a distinct concern and operational posture. `touch-domain` = objective kit management. `open-kit` = subjective viewport launch (with `--cursor`, `--terminal` as viewport targets). `checkpoint` = in-session capture. `distill` = isolated post-session processing. Clean separation means each can evolve independently. `touch-domain` and `distill` are objective (operate from outside). `checkpoint` is subjective (operates from inside). `open-kit` is the transition between them.
- **Revisit if**: Commands need to compose in ways the separation prevents; a fifth concern emerges that doesn't fit

## 2026-03-10: Firehose reframed as attention-direction (future feature)
- **Context**: "Firehose" was originally the name for the whole system and the serial sweep command. As the command taxonomy crystallized, firehose became one feature among several — and a different kind of feature: not kit management or viewport launching, but strategic scanning across all domains to surface what needs attention.
- **Alternatives considered**: Keep firehose as the system name, implement sweep immediately
- **Deciding factors**: The core commands (touch-domain, open-kit, checkpoint, distill) need to be proven in daily use before building the sweep. Firehose as attention-direction is a System 4 function (VSM) — intelligence, looking outward and forward. Different from System 2/3 (coordination/control, which is touch-domain) and System 1 (operations, which is open-kit + checkpoint). Design deferred until core is stable.
- **Revisit if**: The need for cross-domain scanning becomes urgent before core commands are proven

## 2026-03-10: Domain kit as foundational concept (variety-agent-design lineage)
- **Context**: The domain kit concept originates from cybernetics-grounded analysis of human-agent systems (Ashby's Law of Requisite Variety, Beer's Viable System Model). The term "domain kit" was coined in this project to describe the complete set of domain-specific resources a model is given access to — a viable system, not just a prompt.
- **Alternatives considered**: Using mainstream terminology ("context engineering", "agent skills", "prompt templates")
- **Deciding factors**: Existing terms don't capture the governance dimension — the session-distillation loop, variety engineering, completeness bias management, the domain kit as an ontological space. "Domain kit" does real work that existing vocabulary doesn't. The .context/ directory structure is a direct implementation of the domain kit concept: Configuration (agent.md, README.md) + State (MEMORY.md, DECISIONS.md, STATE.md, sessions/).
- **Revisit if**: "Domain kit" collides with an established term in the field; a better term emerges
