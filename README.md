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
- **A distillation loop for reasoning continuity.** Session artifacts are processed by an isolated distiller — a separate agent providing objective review. Knowledge compounds across sessions.
- **Claude Code superpowers.** Orchestration of subagents, model selection per domain, objective and adversarial review via isolated headless invocations, hooks for deterministic automation.

## Commands

Three concerns, three commands:

**`touch-domain`** — kit management. Structural health, git state, profiling, scaffolding, bootstrapping. Operates from the outside, objectively. Modes: default (smart touch), `--full` (profile regeneration), `--new` (new domain bootstrapping). Modifiers: `--no-touchy` (read-only diagnostic), `-y` (suppress prompts).

**`open-domain`** — viewport launch. Opens a managed domain for interactive work. `open-domain cashflow --cursor` opens the domain in Cursor/VS Code. The transition from objective observation to subjective immersion.

**`distill`** — memory processing. Transforms session artifacts into proposed updates to canonical files. Runs in isolated context — no access to the working session's conversation history. This is a debiasing mechanism: the distiller reads cold artifacts off disk without completion bias or sunk-cost reasoning.

## User story

You open a terminal. You're in the orchestrator — Claude Code running in the system repo. You run `touch-domain --no-touchy` across the registry. The agent reports back: domain statuses, git states, stale profiles, unprocessed sessions, revisit conditions that look met. You see the landscape.

You pick a domain. `open-domain cashflow --cursor`. A new VS Code window appears. PROFILE.md, MEMORY.md, DECISIONS.md open as tabs. Claude Code launches in the extension panel, loads context via hooks, and briefs you: "Last session was March 3rd. STATE shows the reconciliation module is blocked on API access. DECISIONS has a revisit condition that appears met — the vendor shipped their v2 API last week. Three unprocessed sessions pending distillation."

You're in discourse. You work. The agent surfaces files as tabs when they become relevant. You hit decision points — the agent captures them. Session artifacts accumulate in `.context/sessions/`.

Back in the orchestrator, you kick off `distill cashflow`. A headless, isolated agent reads the session artifacts against the canonical files and proposes updates. You review the diff. Approve. MEMORY and DECISIONS grow. The domain is smarter for next time.

Or you start something new. `touch-domain --new ~/domains/new-client`. "This path doesn't exist. Starting new domain onboarding." An interactive session begins — you define the domain, its scope, the agent persona, initial concerns. That conversation is captured as the first session. Git initializes. The bare repo appears on your server. The workspace file generates. The viewport opens. The domain is born version-controlled, context-aware, and ready.

## Design documents

- `orchestrator-architecture.md` — commands, viewport, runtime, hooks, implementation path
- `domain-convention.md` — domain layout, file roles, git convention, lifecycle
- `distiller-spec.md` — distillation pipeline, isolation requirement, strategies, review gate

## Current state

Spec-revised, scope expanding. See `.context/STATE.md` for details.
