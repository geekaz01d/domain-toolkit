# Domain Kit Engineering (working title)

## What this is

Infrastructure for durable human-agent collaboration. Not per-session, not per-task — persistent, across time, with memory and accountability.

A **domain** is any concern you manage — a project, a client, a system, a body of research. Each domain carries a **domain kit**: the combination of all domain-specific resources that a model is given access to — prompts, personas, context, state, memories, tools, skills — plus a session-distillation loop that gives agents reasoning continuity and humans a feedback gate.

The domain kit is the basic unit of governance in the system. It is not a prompt. It is a complete ontological space within which an agent reasons. Grounded in cybernetics (Ashby's Law of Requisite Variety, Beer's Viable System Model).

## Why

You have many concerns. Each one has context that matters — decisions made, constraints discovered, preferences learned, work in progress. Without a system, that context lives in your head or scatters across chat logs. Every new agent session starts from zero. You re-explain. The agent re-discovers. Knowledge doesn't compound.

This system makes the domain kit the unit of collaboration. The agent reads the kit on entry and contributes to it on exit. The distiller ensures quality. Git provides the audit trail. Over time, each domain's kit becomes a genuinely useful knowledge base — not just a project folder.

**What it provides:**

- **Normalized domain kits** across all domains. Every concern follows the same convention, so any agent entering any domain knows what to read, what to write, and what not to touch.
- **Context and intention hygiene.** Different clients, different concerns, different agent personas — cleanly separated. No context leakage between domains.
- **Clarity and continuity per domain.** MEMORY accumulates. DECISIONS record rationale with revisit conditions. PROFILE synthesizes state plus context into a one-page briefing. Every session starts warm, not cold.
- **Principal awareness.** The domain kit knows who might interact with it — enabling transferability between humans and onboarding of new agents.
- **Session capture from inception.** Domain creation is a session. The onboarding conversation that defines a domain is itself the first session artifact.
- **Housekeeping and git awareness.** `touch-domain` is the universal health check. Concerns are surfaced, not silently fixed.
- **A viewport for interactive work.** `open-domain --cursor` opens a domain in its own VS Code window with context files visible and Claude Code at the center.
- **Sets and worktrees.** Group related domains, assemble them as git worktrees, open a set as a unified workspace.
- **A distillation loop for reasoning continuity.** Session artifacts are processed by an isolated distiller — a separate agent providing objective review. Knowledge compounds across sessions.
- **Claude Code superpowers.** Orchestration of subagents, model selection per domain, objective and adversarial review via isolated headless invocations, hooks for deterministic automation.

## Commands

| Command | Concern |
|---------|---------|
| **`touch-domain`** | Kit management. Structural health, git state, profiling, scaffolding, bootstrapping. Operates from the outside, objectively. |
| **`open-domain`** | Viewport launch. Opens a domain or set for interactive work. Cursor, terminal, or containerised viewport. |
| **`add-domain`** | Registry management. Scan, register, scaffold new domains. Builds the derived REGISTRY.yaml from domain.yaml files on disk. |
| **`group-domain`** | Set management. Organise domains into named groups via domain.yaml `sets` field. |
| **`rename-domain`** | Domain identity. Rename the logical name (`name` field in domain.yaml) and rebuild the registry. Does not touch repo name, directory, or remotes — storage reorganisation is a separate concern. |
| **`distill-domain`** | Memory processing. Transforms session artifacts into proposed updates to canonical files. Runs in isolated context — no access to the working session's conversation history. Debiased by design. |
| **`overview`** | Capacity-aware briefing. Scans the registry, filters through the personal domain profile, produces a prioritised view of what deserves attention. |

## Domain structure

Each managed domain contains:

- `README.md` — canonical description of what this domain is
- `.claude/domain-toolkit/domain.yaml` — machine-readable manifest and detection signal (tracked in git)
- `persona.md` — agent identity, context map, behavioural settings (tracked in git)
- `CLAUDE.md` — domain-specific governance (tracked in git)
- `.context/` — knowledge layer: `PROFILE.md`, `MEMORY.md`, `DECISIONS.md`, `STATE.md`, `sessions/` (gitignored, synced via Syncthing)

## User story

You open a terminal. You're in the orchestrator — Claude Code running in the system repo. You run `touch-domain --no-touchy` across the registry. The agent reports back: domain statuses, git states, stale profiles, unprocessed sessions, revisit conditions that look met. You see the landscape.

You pick a domain. `open-domain cashflow --cursor`. A new VS Code window appears. PROFILE.md, MEMORY.md, DECISIONS.md open as tabs. Claude Code launches in the extension panel, loads context via hooks, and briefs you: "Last session was March 3rd. STATE shows the reconciliation module is blocked on API access. DECISIONS has a revisit condition that appears met — the vendor shipped their v2 API last week. Three unprocessed sessions pending distillation."

You're in discourse. You work. The agent surfaces files as tabs when they become relevant. You hit decision points — the agent captures them. Session artifacts accumulate in `.context/sessions/`.

Back in the orchestrator, you kick off `distill-domain cashflow`. A headless, isolated agent reads the session artifacts against the canonical files and proposes updates. You review the diff. Approve. MEMORY and DECISIONS grow. The domain is smarter for next time.

Or you start something new. `touch-domain --new ~/domains/new-client`. "This path doesn't exist. Starting new domain onboarding." An interactive session begins — you define the domain, its scope, the agent persona, initial concerns. That conversation is captured as the first session. Git initializes. The bare repo appears on your server. The workspace file generates. The viewport opens. The domain is born version-controlled, context-aware, and ready.

## Design documents

See `docs/specs/` for the full specification set:

- `command-taxonomy.md` — commands, concerns, relationships
- `file-convention.md` — file hierarchy, load order, persona placement
- `domain-yaml-schema.md` — domain.yaml schema
- `domain-model-semantics.md` — domain types, authorship vs operation, overview function
- `registry-spec.md` — derived registry, scan paths, sets index
- `set-assembly-spec.md` — worktree assembly, set roots, Docker integration, custodial checklist, agentic git operations, git recovery
- `storage-and-services.md` — storage topology, containerised viewports, Syncthing overlay
- `distiller-spec.md` — distillation pipeline, strategies, review gate
- `sandbox-test-data.md` — demo sandbox specification
- `orchestrator-architecture.md` — original architecture (partially superseded)
- `domain-convention.md` — original convention (partially superseded)
- `git-operations.md` — original git consolidation (superseded by set-assembly-spec.md)

## Current state

Spec-revised, scope expanding. See `.context/STATE.md` for details.
