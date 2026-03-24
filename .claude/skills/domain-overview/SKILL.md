---
name: domain-overview
description: "Capacity-aware briefing: scan the registry, filter through the personal domain profile, and synthesize a prioritised attention picture."
model: opus
argument-hint: "[@group]"
---

You are implementing the **`overview`** command from `command-taxonomy.md`. This is a System 4 function — intelligence and attention direction. You scan the domain landscape and synthesize a capacity-aware briefing for the operator.

Read `domain-model-semantics.md` for the overview function design. Read `registry-spec.md` for the registry format and currency signal.

## Core Principle

**The personal domain is read FIRST, as the lens.** You do not scan all domains and then filter — you understand the operator's state, capacity, and constraints first, then view all subject domains through that lens. Output is attention-direction — not instructions, not action items. The operator decides what to open next.

## Argument Parsing

If `$ARGUMENTS` is `--help`, `--usage`, or `-h`, print this usage summary and stop:

```
domain-overview — Capacity-aware briefing

Usage: /domain-overview [@group]

Options:
  @<group>   Scope the overview to a single set (e.g., @infrastructure)
  (none)     Full overview across all domains in the registry
```

Parse `$ARGUMENTS`:

- **No arguments** — Full overview across all domains in the registry
- **`@<group>`** — Scoped overview for a single set (e.g., `@infrastructure`, `@geekazoid`)

## Step 1: Load the Personal Domain

1. Read `~/.claude/domain-toolkit/REGISTRY.yaml`.
2. Find the domain with `type: personal`. There should be exactly one. If none found, proceed without capacity filtering but note: "No personal domain found in registry. Operating without capacity context — briefing will be unfiltered."
3. If a personal domain exists, expand its `path` (replace `~` with `$HOME`) and read:
   - `.context/PROFILE.md` — synthesized overview of the operator
   - `.context/STATE.md` — current volatile state
   - `.context/MEMORY.md` — persistent knowledge about the operator
   - `persona.md` — operator identity and context
4. Extract from these files:
   - **Current capacity**: Is the operator at full capacity, constrained, recovering, overwhelmed?
   - **Active priorities**: What areas or projects have declared focus?
   - **Constraints**: Time limits, energy levels, blocked-on items, scheduled commitments
   - **Areas of concern**: The `areas:` field in the personal domain's registry entry or domain.yaml
5. Hold this as the filtering lens for everything that follows.
6. If the personal domain's `.context/` files don't exist or are empty (e.g., `kit_health: no`), note: "Personal domain exists but has no context files. Operating without capacity context." Proceed with unfiltered mode.

## Step 2: Scan Registry Domains

1. Read all domain entries from REGISTRY.yaml.
2. If `@<group>` was specified, filter to only domains whose `sets:` include that group name. If the group doesn't exist in the `sets:` index, error: "No set named `<group>` found. Use `group-domain --list` to see available sets."
3. Exclude the personal domain from the subject scan (it was already read as the lens).
4. For each subject domain in scope, collect from the registry entry:
   - `name`, `description`, `type`
   - `sets` — group memberships
   - `last_touched` — the currency signal
   - `kit_health` — structural health
   - Any freeform fields that provide context (e.g., `serves`, `children`, `client`, `priority`)

## Step 3: Analyze Currency and Health

For each domain, assess:

### Currency (based on `last_touched`)

Calculate the gap between today's date and `last_touched`:

| Gap | Label |
|-----|-------|
| Today or yesterday | **Active** |
| 2-7 days | **Current** |
| 1-2 weeks | **Drifting** |
| 2-4 weeks | **Stale** |
| >4 weeks or null | **Cold** |

### Health (based on `kit_health`)

- `yes` — Healthy kit, no structural concerns
- `partial` — Some structural issues (missing files, incomplete scaffolding)
- `no` — Kit not set up or severely broken

### Combined Assessment

A domain that is both **Cold** and `kit_health: no` may not have been properly onboarded. A domain that is **Active** and `kit_health: partial` has structural debt accumulating during active work. Weight these differently.

## Step 4: Read Domain Profiles (Selective)

For domains that appear to need attention (drifting, stale, or cold), attempt to read their `.context/PROFILE.md` for richer context. This provides:

- What the domain is working on
- Open threads and blockers
- Recent decisions

Do NOT read profiles for all domains — that is expensive. Prioritize:
1. Domains flagged as **Drifting** or **Stale** that relate to the operator's active priorities
2. Domains with `kit_health: partial` or `no`
3. Any domain the operator's personal domain references (e.g., via `serves` or `areas`)

If a PROFILE.md doesn't exist or the path is unreachable, note it and continue.

## Step 5: Synthesize the Briefing

Structure the output as a capacity-aware briefing. This is NOT a raw data dump. It is a synthesized intelligence product.

### Briefing Format

```
## Overview — <date>
<One or two sentences about the operator's current state and capacity, drawn from the personal domain. If no personal domain context, state that.>

### Active Work
<Domains touched today/yesterday. Brief note on what's happening in each, if known from profiles.>

### Needs Attention
<Domains that are drifting or stale AND relate to active priorities. Explain why they matter given current capacity.>

### Structural Concerns
<Domains with kit_health issues, especially if they're active or drifting. Suggest touch-domain actions.>

### Cold Domains
<Domains that haven't been touched in weeks. Brief note — are they dormant by choice, or forgotten?>

### Suggested Next Action
<One concrete suggestion: which domain to open next and why, given the operator's current state. This is a suggestion, not a directive.>
```

### Capacity Filtering

Apply the personal domain lens throughout:

- If the operator is **constrained**, emphasize only the highest-priority domains and explicitly say "the rest can wait."
- If the operator is **at capacity**, provide a broader view but still prioritize.
- If there's **no personal domain context**, provide an unfiltered view sorted by currency, and note that capacity filtering is unavailable.
- Never present more than the operator can reasonably act on. Five domains needing attention is actionable; fifteen is noise.

### Tone

- Direct and concise. Not chatty, not bureaucratic.
- Honest about gaps. If you don't have enough context to assess a domain, say so.
- Respect the operator's agency. Present the landscape; don't dictate the response.

## Handling Edge Cases

- **No personal domain** — Proceed without capacity filtering. Note this at the top of the briefing. Suggest: "Register a personal domain (type: personal) to enable capacity-aware filtering."
- **Empty registry** — "No domains registered. Use `add-domain <path>` or `add-domain --update` to populate the registry."
- **All domains active** — Good news. Say so briefly and note any structural concerns.
- **All domains cold** — This is a signal in itself. Note it. Suggest starting with the domain closest to the operator's current priorities.
- **Filtered subset (`@group`)** — Only scan domains in the named set, but still read the personal domain for capacity context. Adjust the briefing header: "Overview — <date> (filtered: @<group>)"
- **Unreachable domain paths** — Note which domains couldn't be reached (path doesn't exist, not mounted). Don't fail the whole briefing.
