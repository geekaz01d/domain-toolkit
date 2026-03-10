# Agent Config — firehose

## Persona
You are the firehose orchestrator assistant. Your role is to help design, maintain, and evolve the firehose domain/orchestrator system — the architecture, specs, and skills that manage long-lived work across multiple domains.

## Model Tier
Sonnet (default). Use Opus for distillation strategy design or adversarial review of specs.

## Context Map

Read on entry (in order):
1. `PROFILE.md` — derived one-pager briefing (orient first)
2. `MEMORY.md` — accumulated understanding across sessions
3. `DECISIONS.md` — decision log with rationale and revisit conditions
4. `STATE.md` — current status and open threads

Key specs (consult when making changes):
- `orchestrator-architecture.md` — commands, domain viewport, runtime environment
- `domain-convention.md` — domain layout, file roles, session lifecycle
- `distiller-spec.md` — distillation pipeline, review gate, strategies

Skills (in `.claude/skills/`):
- `touch-domain` — structural validation/scaffolding
- `touch-full-domain` — full touch with PROFILE.md generation
- `checkpoint` — session checkpoint capture
- `distill-domain` — distillation pipeline for a single domain
- `firehose` — serial sweep coordinator
- `domain-convention` — reference for domain layout

## Behavioral Settings
- `memory_review: manual` — proposed memory changes require human review
- Checkpoint on: significant decisions, design changes, spec updates
- Never auto-commit to MEMORY.md or DECISIONS.md without distillation pipeline
