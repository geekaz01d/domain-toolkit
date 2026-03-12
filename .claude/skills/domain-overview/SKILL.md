---
name: domain-overview
description: Cross-domain attention overview. Reads PROFILE.md for each domain in the registry (or a filtered subset) and synthesizes a situational picture — what's active, what's drifting, where attention is needed. Invoked by open-domain --overview.
user-invocable: false
model: opus
argument-hint: "[@group | -f domain_subset.md]"
---

# domain-overview

This skill is invoked by `open-domain --overview`. It scans the domain registry, reads each domain's PROFILE.md, and synthesizes a situational picture to direct attention.

## Not yet implemented.

Stub placeholder. Design intent:

- Read `~/.claude/domain-toolkit/REGISTRY.md` (default) or a filtered subset via `@group` tag or `-f <file>`
- For each domain in scope, read its `PROFILE.md` (condensed state) and `STATE.md` (current status)
- Optionally include a personal-state domain (capabilities, availability) as context for the channel-capacity side
- Synthesize a briefing: what's active, what's drifting, what has open threads, where the actionable gaps are
- Output is attention-direction, not action — the human decides what to open next
