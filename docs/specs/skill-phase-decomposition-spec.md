# Skill Phase Decomposition Spec

**Status:** Draft — 2026-03-24
**Context:** Addresses instruction-following degradation in domain-toolkit skills. Grounded in "Curse of Instructions" (ICLR), IFScale (Feb 2026), "Lost in the Middle" (Liu et al., TACL 2024), and Microsoft agent-skills progressive disclosure pattern. Prompted by Dani's feedback on execution enforcement (2026-03-20).

---

## Problem

Each domain-toolkit SKILL.md is a monolithic instruction document containing multiple modal protocols. The agent loads the entire file on skill invocation and must self-select the relevant protocol based on argument parsing — a probabilistic task that research shows degrades reliably as instruction count increases.

The degradation is not hypothetical. IFScale (2026) measured three distinct patterns across 20 frontier models: threshold decay (reasoning models), linear decay (Claude Sonnet 4), and exponential decay (GPT-4o). The "Curse of Instructions" paper found that the probability of following all N instructions scales as p^N where p is the per-instruction success rate. Separately, research shows that sheer input length degrades reasoning performance even when the model correctly retrieves relevant information — irrelevant protocol text is not inert, it is actively harmful.

The deterministic parts of the system (hooks, stager, installer — all code) are unaffected. The problem is specifically the `.claude/skills/` layer where natural language instructions substitute for code execution.

---

## Design Principles

1. **Classify first, load second.** The skill entry point determines the mode, then loads only the instructions for that mode.
2. **Phases are files, not sections.** Each mode's protocol lives in its own file. The gate reads one file. No in-document extraction or section parsing.
3. **The gate is minimal.** The classification gate is the smallest possible instruction set: parse arguments, identify mode, read the phase file. Nothing else.
4. **Shared context is a reference, not inline.** Content shared across modes (registry format, domain.yaml schema, error patterns) lives in reference files that phases point to — not duplicated into each phase.
5. **The existing seam.** The domain-toolkit already implements progressive disclosure at the domain entry level (hooks load context files on demand). Apply the same pattern within skills.

---

## Architecture

### Current (monolithic)

```
.claude/skills/<skill>/
  SKILL.md          # All modes, all protocols, all error handling
```

The agent reads the full SKILL.md. Every mode's instructions compete for attention regardless of which mode was invoked.

### Target (gated phases)

```
.claude/skills/<skill>/
  SKILL.md          # Classification gate only — frontmatter + argument parsing + phase dispatch
  phases/
    <mode-a>.md     # Complete protocol for mode A
    <mode-b>.md     # Complete protocol for mode B
    ...
  refs/
    <shared>.md     # Shared reference material (loaded by phases that need it)
```

The agent reads SKILL.md (small), classifies the mode, then reads exactly one phase file. Phases read refs on demand.

### Gate pattern

SKILL.md becomes a lightweight dispatcher:

```markdown
---
name: <skill-name>
description: "<unchanged — trigger matching still works>"
argument-hint: "<unchanged>"
---

You are implementing the **`<command>`** command from `command-taxonomy.md`.

## Argument Classification

Parse `$ARGUMENTS` for flags and positional arguments. Identify which mode applies:

| Arguments | Mode | Phase file |
|-----------|------|------------|
| `<path>` (no flags) | Register single | `phases/register.md` |
| `--update` | Update registry | `phases/update.md` |
| `--new <path>` | Scaffold new | `phases/new.md` |
| `--scan-path <path>` | Add scan path | `phases/scan-path.md` |

**Read the identified phase file now and follow its instructions.** Do not proceed without reading the phase file.

If arguments don't match any mode, report usage and stop.
```

That's it. The gate is ~20 lines. The agent's instruction-following task at this point is: parse arguments, match a row, read a file. Three instructions, not thirty.

---

## Decomposition Plan

### Priority 1 — High mode count, high usage

#### `touch-domain`

Currently the largest SKILL.md. Five modes (default, `--full`, `--new`, `--all`, `--no-touchy` modifier), each with multi-step procedures. Git precheck is a shared concern across modes.

```
.claude/skills/touch-domain/
  SKILL.md                    # Gate: classify mode
  phases/
    default.md                # Structural validation only
    full.md                   # Validation + content synthesis + PROFILE.md regen
    new.md                    # Interactive onboarding + scaffolding + git init
    all.md                    # Registry sweep (wraps full.md per domain)
  refs/
    git-precheck.md           # The 5-state git precheck table + actions
    structural-checklist.md   # The validation checks shared by default and full
    no-touchy.md              # Modifier semantics (composes with any phase)
```

The `--no-touchy` modifier applies across modes. Include it as a ref that each phase reads if the flag is present, rather than duplicating its semantics into every phase.

#### `add-domain`

Four modes, each self-contained.

```
.claude/skills/add-domain/
  SKILL.md                    # Gate: classify mode
  phases/
    register.md               # Single domain registration
    update.md                 # Full registry scan and rebuild
    new.md                    # Scaffold + register (delegates to touch-domain)
    scan-path.md              # Add a scan path to REGISTRY.yaml
  refs/
    registry-format.md        # REGISTRY.yaml structure (shared across modes)
    path-normalization.md     # ~ expansion, absolute path rules
```

### Priority 2 — High risk (headless execution)

#### `distill-domain`

Runs headless without human correction. Currently a single protocol but with distinct phases that could benefit from sequential loading.

```
.claude/skills/distill-domain/
  SKILL.md                    # Gate: identify inputs, check for --re-synth
  phases/
    identify.md               # Scan sessions, select closed, sort chronologically
    synthesize.md             # The core reasoning protocol (read state, read sessions, produce output)
    write.md                  # Write MEMORY.md, DECISIONS.md, mark sessions distilled
  refs/
    conflict-handling.md      # Conflict detection and DISTILL-CONFLICTS.md format
    provenance-format.md      # Frontmatter format for synthesized files
```

Note: distill-domain's phases are sequential (identify → synthesize → write), not modal. The gate reads `identify.md` first, then chains to `synthesize.md`, then `write.md`. Each phase completes before the next loads. This keeps the synthesis reasoning phase free of I/O mechanics.

### Priority 3 — Lower risk, simpler

#### `domain-overview`

Five steps, currently one document. The steps are sequential and could benefit from isolation, but the total instruction volume is moderate. Decompose if empirical testing shows drift.

#### `open-domain`, `group-domain`, `rename-domain`

Simpler skills with fewer modes. Candidates for decomposition but lower priority. Monitor for drift before investing.

#### `domain-convention`, `install-domain-toolkit`

`domain-convention` is a reference skill (not user-invocable) — no execution protocol to decompose. `install-domain-toolkit` delegates to a shell script — the skill is already a thin wrapper.

---

## Shared References

Some content is currently duplicated across skills or inlined into skills that only need it occasionally. Extract into refs:

| Ref file | Content | Consumed by |
|----------|---------|-------------|
| `registry-format.md` | REGISTRY.yaml structure, field reference | add-domain, group-domain, domain-overview |
| `domain-yaml-fields.md` | domain.yaml schema quick reference | add-domain, touch-domain, rename-domain |
| `git-precheck.md` | 5-state table, actions, `-y` behavior | touch-domain (all phases), open-domain |
| `path-normalization.md` | `~` expansion rules, absolute path conventions | add-domain, group-domain, rename-domain |
| `error-patterns.md` | Common error messages and suggested fixes | all skills |

Refs are not loaded by the gate. They are loaded by phases that reference them. A phase that doesn't need the git precheck never sees it.

---

## Loading Mechanics

Claude Code skills use `Read` tool calls to load files. The gate pattern relies on the agent reading the phase file after classification. This is the same mechanism used today when skills reference spec files ("Read `registry-spec.md` for the canonical registry format").

The key difference: today, the instruction to read a spec is one of many instructions competing for attention in a long SKILL.md. In the gated pattern, the instruction to read the phase file is one of three instructions in a short gate document. The probability of the agent actually performing the read is dramatically higher.

### What if the agent skips the phase file read?

This is the residual risk. Mitigations:

1. **Gate brevity.** The fewer instructions in the gate, the higher the compliance rate. Three instructions (parse, classify, read) is well within the reliable range.
2. **Explicit instruction.** The gate ends with a bold directive: "**Read the identified phase file now and follow its instructions.** Do not proceed without reading the phase file."
3. **No inline fallback.** The gate contains zero procedural content. If the agent skips the read, it has nothing to work from — it cannot confabulate a plausible protocol because the gate gives it nothing to riff on. This is a deliberate design choice: the failure mode is "I don't know what to do" (recoverable) rather than "I did the wrong thing confidently" (harmful).

---

## Migration Path

### Step 1 — Decompose touch-domain (highest impact)

1. Extract each mode's instructions from the current SKILL.md into `phases/*.md`.
2. Extract git precheck and structural checklist into `refs/`.
3. Replace SKILL.md body with the classification gate.
4. Test each mode independently. Compare output quality against the monolithic version.
5. Check for regressions: does the agent still handle edge cases (missing domain.yaml, dirty git state, `--no-touchy` modifier)?

### Step 2 — Decompose add-domain

Same pattern. Four modes → four phase files + shared refs.

### Step 3 — Decompose distill-domain

Sequential phases rather than modal. Test carefully — this runs headless.

### Step 4 — Evaluate remaining skills

Run the simpler skills (open-domain, group-domain, rename-domain) as-is. Decompose only if empirical testing shows instruction-following drift.

### Step 5 — Document the pattern

Update `file-convention.md` and `CLAUDE.md` to describe the gate + phase pattern as the standard for skill authoring. Future skills should be written decomposed from the start.

---

## Validation

### Structural linting (automated)

`.claude/domain-toolkit/bin/lint-skills` validates skill directory structure against the conventions in this spec. It runs two tiers of checks:

**Universal checks** (all skills, monolithic or decomposed):
- Frontmatter exists with required fields (`name`, `description`)
- `name` matches the skill directory name
- User-invocable skills have `argument-hint`
- Backtick-quoted spec file references (e.g., `` `registry-spec.md` ``) resolve to files in `docs/specs/`
- No orphan files in the skill directory (every non-SKILL.md file is referenced)

**Decomposed checks** (when `phases/` directory exists):
- Every gate table row pointing to `phases/*.md` resolves to a file on disk
- No orphan phase files (present in `phases/` but not referenced in the gate table)
- Every `refs/*.md` reference from phases or gate resolves to a file on disk
- No orphan ref files (present in `refs/` but not referenced by any phase or gate)
- Gate SKILL.md body is under a size threshold (catches leaked procedural content)
- Phase files do not cross-reference other phases (chaining is driven by the gate)

Run the linter before and after decomposition to catch mechanical errors. It is not a substitute for behavioral testing (see below) but it eliminates an entire class of breakage — missing files, stale references, orphaned content.

### Per-skill testing (manual)

For each decomposed skill:

1. Run the skill in each mode 3-5 times with representative inputs.
2. Compare: does the agent follow the protocol steps in order? Does it skip steps? Does it confuse modes?
3. Measure qualitatively against the monolithic version. The bar is: same or better protocol compliance, not perfection.

### Regression markers

Watch for these failure modes after decomposition:

- Agent classifies mode correctly but fails to read the phase file (gate too complex or directive too weak).
- Agent reads the phase file but also "remembers" content from the gate that biases its behavior (gate leakage — keep the gate content-free).
- Agent reads a ref file that the phase didn't ask for (ref loading should be explicit in the phase, not in the gate).
- Sequential phases (distill-domain) executed out of order or skipped.

### Success criteria

The decomposition is successful when:

- Each mode's protocol is followed with equal or better fidelity than the monolithic version.
- The total token load per skill invocation is reduced (gate + one phase < full monolithic SKILL.md).
- Adding a new mode to an existing skill requires adding one phase file and one row in the gate table — no changes to other phases.

---

## Relationship to Existing Specs

This spec does not change any domain-toolkit semantics — commands still do what `command-taxonomy.md` says they do. It changes only how skill instructions are organized and loaded.

| Spec | Relationship |
|------|-------------|
| `command-taxonomy.md` | Unchanged. Commands, concerns, and relationships are the same. |
| `file-convention.md` | Extended. Add the `phases/` and `refs/` convention for skills. |
| `CLAUDE.md` | Updated. Describe the gate + phase pattern in the skills section. |
| `distiller-spec.md` | Unchanged. The distillation protocol is the same; it's just loaded in phases. |
| `install-spec.md` | Unchanged. Install delegates to a shell script already. |

---

## References

- Jiang et al. (2024) — "Curse of Instructions" — exponential instruction-following decay, ICLR
- Jaroslawicz et al. (2026) — "How Many Instructions Can LLMs Follow at Once?" (IFScale) — degradation patterns across 20 models
- Liu et al. (2024) — "Lost in the Middle" — positional attention degradation, TACL
- Levy et al. (2025) — "Context Length Alone Hurts LLM Performance" — length-independent reasoning degradation
- Microsoft agent-skills — progressive disclosure / context rot prevention pattern
- Anthropic Agent Skills docs — three-tier progressive loading (frontmatter → body → references)
