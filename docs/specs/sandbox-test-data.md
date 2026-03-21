# Sandbox Test Data Spec

## Purpose

Provide a self-contained sandbox that demonstrates domain-toolkit managing a realistic constellation of domains. The sandbox simulates a user's home directory with domain-toolkit installed and several active domains representing a mix of knowledge work and software projects.

The primary demo target is `domain-overview` — showing how the system surfaces what needs attention across a user's full domain portfolio, anchored to the human's constraints, capacity, and time.

## Sandbox Layout

```
sandbox/
  home/
    .claude/
      domain-toolkit/
        REGISTRY.yaml            # Live registry — all sandbox domains (includes scan paths)
      hooks/
        session-start.sh         # SessionStart hook (can be a stub for demo)
    sources/
      second-brain/              # PKM repo — the anchor domain
      webshop/                   # E-commerce app (Django + HTMX)
      dotfiles/                  # Personal system config
      infra/
        homelab/                 # Homelab infrastructure (Ansible/Docker)
    Documents/
      consulting/
        acme-discovery/          # Client engagement (knowledge work)
```

## Registry

| Domain | Path | Kit | Character |
|--------|------|-----|-----------|
| second-brain | ~/sources/second-brain | yes | PKM — user's knowledge graph, areas of life, active projects |
| webshop | ~/sources/webshop | yes | Side project — Django e-commerce with HTMX frontend |
| dotfiles | ~/sources/dotfiles | yes | System config — lightweight domain, mostly maintenance |
| homelab | ~/sources/infra/homelab | yes | Infrastructure — Docker Compose services, Ansible playbooks |
| acme-discovery | ~/Documents/consulting/acme-discovery | yes | Client work — discovery phase engagement, time-boxed |

Five domains is enough to demonstrate sweep, overview, and the attention-direction problem without being overwhelming.

---

## Domain: second-brain

### Concept

A personal knowledge management system loosely based on the cursus topology, simplified for a single user. The key insight for the demo: second-brain is the domain that *anchors the user to reality*. It contains the user's self-model — constraints, capacity, commitments, rhythms — which the domain-overview command uses to contextualize attention across all other domains.

### Topology

```
second-brain/
  .claude/
    domain-toolkit/
      domain.yaml
  persona.md
  .context/
    PROFILE.md
    MEMORY.md
    DECISIONS.md
    STATE.md
    sessions/
  README.md

  inbox/                    # Unsorted capture
    2026-03-10-meeting-notes.md
    2026-03-11-idea-llm-grading.md
    2026-03-12-article-clip.md

  areas/                    # Ongoing life areas (no end date)
    health/
      running-log.md
      supplements.md
    finances/
      budget-2026.md
      tax-prep-notes.md
    career/
      goals-2026.md
      skills-inventory.md

  projects/                 # Active projects (have an end state)
    webshop-launch/
      plan.md
      checklist.md
    homelab-migration/
      requirements.md
      timeline.md
    blog-relaunch/
      content-calendar.md
      draft-first-post.md

  tasks/                    # Actionable items, loosely GTD-flavored
    backlog.md              # Someday/maybe
    this-week.md            # Current sprint
    waiting-for.md          # Blocked/delegated items

  domains/                  # Cross-references to managed domains
    README.md               # How this directory relates to the domain registry
    webshop.md              # Notes on the webshop domain from PKM perspective
    homelab.md              # Notes on homelab from PKM perspective
    acme-discovery.md       # Notes on the client engagement

  kb/                       # Knowledge base — reference material
    tools/
      claude-code-tips.md
      cursor-workflows.md
      docker-cheatsheet.md
    concepts/
      domain-driven-design.md
      gtd-methodology.md
    people/
      mentors.md
      collaborators.md

  profile/                  # User self-model — the demo anchor
    me.md                   # Identity, values, working style
    capacity.md             # Current bandwidth, energy patterns, constraints
    commitments.md          # Active obligations with time horizons
    rhythms.md              # Weekly/daily patterns, review cadences
    environment.md          # Tools, workspace setup, physical environment
```

### Profile Directory — The User Anchor

The `profile/` directory is what makes second-brain special for the domain-overview demo. These files give the overview agent a model of the human, not just the domains.

**`me.md`** — Who the user is. Role, background, values, working style preferences. Not a resume — a self-model the agent can reference when prioritizing.

Example content:
```markdown
# Me

Software engineer, 15 years. Currently independent consultant + side projects.
Value: shipping over perfecting. Bias toward action but tend to overcommit.
Learning edge: systems thinking, cybernetics, agent-augmented workflows.
```

**`capacity.md`** — Current bandwidth. Updated regularly (ideally weekly). This is the scarcest resource and the one that makes attention-direction meaningful.

Example content:
```markdown
# Capacity — Week of 2026-03-10

Available hours: ~30 (reduced — school break, kids home afternoons)
Energy: moderate. Sleep has been inconsistent.
Focus blocks: mornings 8-11 are protected. Afternoons are fragmented.

## Allocation
- Acme discovery: 12h (contracted, non-negotiable)
- Webshop: 8h (launch target is March 21)
- Homelab: 3h (migration has a hard deadline — ISP change March 15)
- Everything else: 7h (admin, PKM review, dotfiles, misc)

## Constraints
- March 15: ISP switchover — homelab must be migrated before this
- March 21: Webshop soft launch target
- March 28: Acme discovery deliverable due
```

**`commitments.md`** — What's promised, to whom, by when. The overview agent checks this against domain STATE.md files to surface conflicts.

**`rhythms.md`** — When reviews happen, what cadences are established. Helps the overview agent know *when* to flag things vs. when they're expected to be stale.

Example content:
```markdown
# Rhythms

## Weekly
- Monday morning: week planning (update this-week.md, review capacity)
- Friday afternoon: week review (process inbox, update STATE files)

## Monthly
- First Saturday: full domain sweep, profile regeneration
- Mid-month: financial review (budget reconciliation)

## Ad hoc
- Before any client call: review that domain's STATE and recent sessions
- After any deep work block: capture to inbox
```

**`environment.md`** — Physical and digital workspace. Relevant for the agent to understand tooling constraints.

### second-brain `.context/` Files

**`persona.md`** — Persona is a thoughtful PKM assistant. Knows the user's system, helps maintain it, doesn't over-organize.

**`MEMORY.md`** — Should contain accumulated knowledge about how the user actually uses the system (vs. how it's designed). Things like "user rarely processes inbox on Fridays despite the stated rhythm" or "health/running-log hasn't been updated since January — user mentioned dropping the habit."

**`STATE.md`** — Current PKM status. Inbox count, stale areas, overdue reviews.

Example:
```markdown
# State — second-brain

## Current Status: Inbox growing, weekly review overdue

Inbox has 3 unprocessed items (oldest: March 10).
Last weekly review: March 7.
Last full domain sweep: February 28 — overdue by 2 weeks.

## Areas Needing Attention
- finances/tax-prep-notes.md — tax deadline approaching, notes incomplete
- career/goals-2026.md — Q1 check-in not done

## What's Active
- projects/webshop-launch/ — in progress, linked to webshop domain
- projects/homelab-migration/ — urgent, hard deadline March 15
- projects/blog-relaunch/ — stalled since March 3

## Last Updated: 2026-03-12
```

**`DECISIONS.md`** — PKM-level decisions. Example: "2026-02-15: Adopted weekly capacity tracking in profile/capacity.md. Revisit if: tracking becomes stale for 2+ weeks."

---

## Domain: webshop

### Concept

A Django + HTMX e-commerce side project. Realistic codebase — not a toy. The user is building it solo, aiming for a March 21 soft launch.

### Content Source

Derive from a public Django e-commerce starter/template. Strip git history, populate as if the user has been working on it for ~2 months. Key directories: `shop/`, `templates/`, `static/`, `tests/`, `docker-compose.yml`.

### `.context/` State

- **STATE.md**: Payment integration half-done. Product catalog works. No tests for checkout flow. Launch target March 21 — tight.
- **MEMORY.md**: User prefers HTMX over React for this project. Using Stripe for payments. Has a staging server on the homelab.
- **DECISIONS.md**: Chose HTMX over React (2026-01-20). Chose Stripe over Paddle (2026-02-01, revisit if: Stripe pricing changes or MoR becomes a requirement).

---

## Domain: dotfiles

### Concept

Lightweight domain. Personal system configuration (shell, editor, window manager). Maintained infrequently. Exists mainly to demonstrate that not every domain is high-intensity.

### Content

Typical dotfiles repo: `.bashrc`, `.gitconfig`, Cursor settings, MATE panel config, a `setup.sh` script. Small.

### `.context/` State

- **STATE.md**: Clean. Last session was updating Cursor keybindings. No open threads.
- **MEMORY.md**: User runs Linux Mint, MATE desktop, HiDPI scaling. Prefers minimal customization.

---

## Domain: homelab

### Concept

Docker Compose services and Ansible playbooks for a home server. Currently under pressure — ISP change on March 15 requires migration.

### Content

`docker-compose.yml` (with services: Traefik, Gitea, Nextcloud, monitoring), `ansible/` playbooks, `docs/` with network diagrams and runbooks.

### `.context/` State

- **STATE.md**: Migration in progress. New network config tested but not deployed. DNS cutover not done. **Hard deadline: March 15.** Blocking: need to update Traefik config for new IP range.
- **MEMORY.md**: User's server is called "fluffy". Bare git repos for all projects live there. Gitea is the web UI. Nextcloud is file sync. Monitoring is Grafana + Prometheus.
- **DECISIONS.md**: Chose Traefik over Nginx Proxy Manager (2026-01-05). Revisit if: Traefik config complexity becomes a maintenance burden.

---

## Domain: acme-discovery

### Concept

A consulting engagement — discovery phase for a client called "Acme Corp." Time-boxed (ends March 28). Pure knowledge work — no code. Documents, interview notes, analysis.

### Content

```
acme-discovery/
  README.md
  deliverables/
    discovery-report-draft.md
    stakeholder-map.md
    risk-assessment.md
  interviews/
    2026-02-20-cto-interview.md
    2026-02-25-engineering-leads.md
    2026-03-05-product-team.md
  analysis/
    current-state.md
    gap-analysis.md
    recommendations-draft.md
  admin/
    sow.md                    # Statement of work
    timeline.md
```

### `.context/` State

- **STATE.md**: Discovery report 60% drafted. Two more interviews scheduled. Deliverable due March 28. Risk: user capacity is tight this month (see second-brain/profile/capacity.md).
- **MEMORY.md**: Client's main pain point is deployment velocity. CTO is technical, receptive. Engineering leads are skeptical of external consultants. Product team is enthusiastic.
- **DECISIONS.md**: Scoped to discovery only — no implementation recommendations (2026-02-15, revisit if: client asks for implementation roadmap before discovery is complete).

---

## Demo Scenarios

### 1. Domain Overview (`domain-overview`)

The headline demo. Run `domain-overview` and it reads all PROFILEs, cross-references with second-brain's profile/capacity.md and profile/commitments.md, and produces:

> **Attention Summary — 2026-03-12**
>
> **URGENT: homelab** — ISP migration deadline in 3 days (March 15). Traefik config update is the blocker. You have 3h allocated this week — that's probably not enough. Consider reallocating from webshop.
>
> **AT RISK: acme-discovery** — Deliverable due March 28, report at 60%. Two interviews still pending. 12h/week allocated — on track if interviews happen this week.
>
> **SLIPPING: webshop** — Launch target March 21, payment integration half-done, no checkout tests. 8h allocated. Feasible but no margin.
>
> **OVERDUE: second-brain** — Weekly review overdue (last: March 7). Inbox has 3 items. Full sweep overdue by 2 weeks.
>
> **QUIET: dotfiles** — Clean. No action needed.

This shows the value proposition: the system doesn't just list domains, it *reasons about the user's situation*.

### 2. Touch Sweep (`touch-domain --all`)

Run across all five domains. Shows structural health, git state, profile currency. Quick, objective, no content reading.

### 3. Single Domain Entry (`open-domain webshop --cursor`)

Opens the webshop viewport. Agent loads context, briefs the user on state, and is ready to work on the payment integration.

### 4. Distillation (`distill-domain webshop`)

After a coding session in webshop, run the distiller. Shows session artifacts being processed into proposed MEMORY/DECISIONS updates.

---

## Data Generation Strategy

| Domain | Content Strategy |
|--------|-----------------|
| second-brain | Fully authored — hand-written markdown files. This is the showcase. |
| webshop | Derived — clone a public Django e-commerce starter, strip history, add .context/ |
| dotfiles | Minimal — a handful of config files, mostly stubs |
| homelab | Authored — docker-compose, a few ansible files, docs. Moderate effort. |
| acme-discovery | Fully authored — all knowledge work documents. Moderate effort. |

### Session Artifacts

Each domain with an active kit should have 2-3 session files in `.context/sessions/` to demonstrate the distillation pipeline. At least one domain (webshop) should have staged transcripts ready for distillation demo.

### Git State Variety

To demonstrate `touch-domain` git precheck, domains should have varied git states:

| Domain | Git State | Demo Value |
|--------|-----------|------------|
| second-brain | Clean | Healthy baseline |
| webshop | Ahead (unpushed commits) | Touch surfaces concern |
| dotfiles | No remote | Touch prompts to create remote |
| homelab | Uncommitted changes | Touch surfaces concern (urgent domain with dirty tree) |
| acme-discovery | Clean | Healthy |

---

## Sandbox Bootstrap

The sandbox should be reproducible from a script or skill. Rough steps:

1. Create `sandbox/home/` directory structure
2. Initialize domain-toolkit install (`sandbox/home/.claude/domain-toolkit/`)
3. For each domain: create content, init git, populate `.context/`, set git state
4. Write the registry pointing at sandbox paths
5. Optionally: create some session artifacts for distillation demo

The bootstrap script should be idempotent — running it twice produces the same sandbox.

---

## Open Questions

1. **Sandbox isolation**: Should the sandbox override `$HOME` or use path remapping? Overriding `$HOME` is cleanest for demo but may break other tools.
2. **Real git remotes**: Should we simulate bare remotes (local `--bare` repos) or just have domains with no actual remote? Local bare repos are more realistic.
3. **Content depth for second-brain**: How much actual content in the markdown files? Enough to be readable in a demo, or exhaustive? Recommend: enough for the overview agent to produce meaningful output — 1-2 paragraphs per file, not stubs.
4. **Persona for the sandbox user**: Should we define a specific fictional user, or keep it generic? Recommend: specific. Give them a name, a role, a situation. Makes the demo compelling.
