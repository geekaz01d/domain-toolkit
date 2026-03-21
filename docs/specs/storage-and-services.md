# Storage, Services, and Access Architecture

**Status:** Draft — captured from working session 2026-03-18
**Context:** Documents the current storage topology, service architecture, security model, and the target vision for domain-scoped containerised viewports. Intended as a durable reference for future sessions.

---

## Current State

### Storage Topology

FLUFFY (Unraid server) is the source of truth for all persistent data:

- **Git bare repos**: `fluffy.geekazoid.net:/mnt/user/git/<repo>.git/`
- **Working trees**: `fluffy.geekazoid.net:/mnt/user/sources/<repo>`
- **Application data**: `fluffy.geekazoid.net:/mnt/user/appdata/<service>/`
- **Media and libraries**: various paths under `/mnt/user/`

The laptop (LAPPY1000) accesses FLUFFY over wireless via NFS mounts:

- `~/sources/fluffy_sources` → `/mnt/fluffy/sources`
- `~/sources/fluffy_appdata` → `/mnt/fluffy/appdata`

Local clones of repositories exist on the laptop under `~/sources/`. These track FLUFFY bare repos as their origin remote, with optional GitHub mirrors as secondary remotes.

### Service Architecture

Services run as Docker containers on FLUFFY, managed via CasaOS. Containers are organised into logical groups:

| Group | Containers | Purpose |
|-------|-----------|---------|
| **Library** | calibre-Wellness, calibre-RTFM, calibre-Permaculture, calibre-General, calibre-Food, calibre-AI, calibre-Adult | Calibre library instances per topic |
| **infra** | AdGuard-Home, Bind9 | DNS infrastructure |
| **dev** | vs-claude23, vs-claude22, cursor-stephanie, cursor-richard, obsidian-richard, obsidian-stephanie | Development environments and knowledge tools projected as browser-accessible GUIs |
| **Cursus** | cursus-assistant, Signal-API, LiteLLM | Personal domain services |
| Standalone | claude-desktop, RecipesDB, Recipes, excalidraw, navidrome, plex, nginx, nginx-portal | Various services |

Services run on FLUFFY for **locality to storage** — the data they operate on is local to the host.

### Current Security Model

- **Container isolation**: bind volumes scope what each container can see
- **Access control**: ro/rw flags on bind mounts provide write control
- **Limitation**: this is coarse-grained. Filesystem-level permissions (UID/GID mapping, ACLs) would be finer. True JIT access (mount only when needed) would be ideal but is fragile in practice.

---

## Containerised Domain Viewports (Target Vision)

### Concept

Increasingly, GUI applications (Cursor + Claude Code, Claude Desktop, Obsidian) are run as containers on FLUFFY and projected to the browser. The `dev` container group is the manual implementation of this pattern.

The target is to automate this as part of `open-domain`:

1. **Read the domain kit** — determine what repos, data paths, and tools the domain requires
2. **Spin up a container on FLUFFY** — the appropriate IDE or tool, with the domain's repos bind-mounted (ro or rw as the kit specifies)
3. **Provision a FQDN** — create DNS entry (bind9), configure reverse proxy (nginx)
4. **Health check** — verify the instance is responding
5. **Return the URL** — the output is a URL that can be piped directly to a browser

This makes `open-domain` produce a fully scoped, isolated workspace for any domain, on demand.

### Security Model

The container's bind mounts **are** the permission boundary. A domain viewport gets exactly the mounts its kit declares — nothing more:

- The domain's own repo: rw
- Declared dependencies (e.g. upstream reference clones): ro
- Shared infrastructure paths as needed: ro

This is the practical implementation of scoped file access. The "JIT" aspect is that the container (and its mounts) exist only while the domain is open. The domain kit declares what it needs (authorship); the operator domain (systems-geekazoid) knows how to provision it (operation).

### Provisioning Stack

The existing infrastructure already provides the provisioning layer:

- **Bind9** — DNS provisioning for FQDNs
- **nginx / NginxProxyManager** — reverse proxy, TLS termination
- **Docker** — container runtime
- **CasaOS** — management interface (manual today, automatable)

The `open-domain` skill would orchestrate these components to provision a domain viewport.

### Relationship to Anthropic's Permission Model

Claude Code and the Agent SDK provide their own permission/sandboxing layer:

- **Sandbox mode** (bubblewrap/Seatbelt): kernel-level filesystem and network isolation per agent session
- **Declarative boundaries**: `sandbox.filesystem.allowWrite`, `denyRead`, allowed network domains
- **Permission modes**: `default` (ask), `acceptEdits` (auto-approve file writes), `bypassPermissions`, `dontAsk` (deny unlisted), `plan` (no execution)
- **Hooks**: custom code that can allow, deny, or modify tool requests at interception points

These complement the container-level isolation. A domain viewport container provides the outer boundary (what the OS sees). Claude Code's sandbox provides the inner boundary (what the agent can touch within that container). The domain kit could declare both: bind mounts for the container, and sandbox config for the agent.

---

## Sync Model

### Design Principles

1. **Single writer at a time** — there is no realistic scenario where both the laptop and the server have concurrent uncommitted changes to the same repo
2. **Data integrity over currency** — a stale-but-safe state is always preferable to a current-but-risky one
3. **Git push/pull is the sync mechanism** — no custom sync tooling, no bidirectional file sync
4. **Working trees are custodial** — they exist to serve the bare repo, not the other way around

### How It Works

- **Bare repo on FLUFFY** (`/mnt/user/git/<repo>.git/`) — the canonical source of truth for all versioned content
- **Working trees** (laptop `~/sources/<repo>`, fluffy `/mnt/user/sources/<repo>`, future VPS) — local checkouts. Disposable, rebuildable from the bare repo at any time
- **Push/pull** — the only sync mechanism. You work somewhere, commit, push. When you switch to another machine, pull.
- **`.context/`** — synced via Syncthing across viewport nodes (see Syncthing Overlay Sync below). Not in git.

A working tree that gets out of date isn't a problem — you pull. A working tree that gets corrupted isn't a crisis — you re-clone from the bare repo. The bare repo is the durable asset. Everything else is a checkout.

### `touch-domain` Custodial Checklist

On domain entry, `touch-domain` should surface sync-relevant concerns:

- Is the working tree clean? (uncommitted changes)
- Is it up to date with the bare repo? (unpushed commits, behind remote)
- Is the bare remote reachable?
- Are there branches with unpushed work?

These are surfaced as concerns, not silently fixed.

---

## Syncthing Overlay Sync

### What Syncthing Syncs

Syncthing syncs the **knowledge layer** — `.context/` — per domain across viewport nodes (laptop ↔ fluffy ↔ future VPS). Everything else travels via git.

**Per domain, the sync scope is:**

- `<domain>/.context/` — knowledge layer (sessions, memory, decisions, state, profile)

Git-tracked files (`CLAUDE.md`, `AGENTS.md`, `.claude/domain-toolkit/domain.yaml`, `persona.md`) travel via git push/pull. Syncthing's scope is exclusively `.context/` — the gitignored knowledge layer. These two systems have distinct, non-overlapping scopes.

**Per set root, the same scope applies:**

- `<set_root>/.context/`

### What Syncthing Does Not Sync

- **Repo content** (code, specs, configs) — travels via git push/pull
- **Branches and worktrees** — branch content is a git concern. Getting branch content to another node requires a git merge or pull. Syncthing never syncs across branches.
- **The `.git/` directory** — git's internal state is never synced by Syncthing

### Sync Topology

Each domain is its own Syncthing sync relationship. There is no broad parent-folder sync.

- Laptop's `~/sources/cashflow/.context/` syncs with fluffy's `/mnt/user/sources/cashflow/.context/`
- Each domain is independent. Adding a new domain means adding a new Syncthing sync relationship.
- `add-domain` or `touch-domain` manages Syncthing folder setup as part of domain scaffolding. No manual configuration.

### System-Level Sync

`~/.claude/domain-toolkit/` is synced as its own Syncthing shared folder across nodes. This covers:

- `REGISTRY.yaml` — derived registry (includes scan paths)
- `worktrees/` — set roots and their governance/context (but not the member worktree content, which is git-managed)

### Session Log Principle

The distiller works with the best available signal. Agent-authored session notes (in `.context/sessions/`) are the guaranteed minimum. When richer sources are available (transcripts, gateway logs), the distiller uses them to verify and enrich. Varying resolution across agents, models, and clients is a property of the system, not a defect. The convention sets the floor; discipline in memory and state recording keeps that floor high.

---

## Agentic Write Discipline (Policy — Pending)

Agents writing to disk need to be disciplined. This is a policy concern that requires its own design work, flagged here for future sessions.

### Principles (Emerging)

- **Agentic ops are assistive** — agents can scan, detect drift, propose changes, but humans approve destructive or ambiguous operations
- **The commit is the durable act** — working tree state between commits is ephemeral. Agents should commit meaningful checkpoints, not just write to disk and hope.
- **Audit logs** — agent writes to disk should be logged (what file, what time, which session). This provides feedback for improving agent discipline and is an additional signal for the distiller.
- **Staged writes** — already established in the domain convention: agents write to session files, never to canonical files (MEMORY, DECISIONS) directly. The distiller mediates.

### Open Questions

- What is the audit log format and where does it live?
- How does the audit log relate to the existing session-index.jsonl?
- Should agents be sandboxed per-domain using Claude Code's sandbox config declared in the domain kit?
- What is the policy for agentic git operations? (see `set-assembly-spec.md`)

---

## Open Concerns

### Availability

FLUFFY is a single point of failure. If it's down: no git origins, no working trees, no running services, no NFS-mounted data. The laptop has local clones of some repos but loses access to services and server-side data.

### Remote Access

Current access is over local wireless. Working away from home means no access to FLUFFY unless VPN or external exposure is configured.

### VPS as Live Runtime

An open design question: what if FLUFFY remained the source of truth (git bare repos, canonical data) but a VPS ran the live services? This would provide better availability, external reachability, and separation of storage from compute. Open questions include which services move, data flow between FLUFFY and VPS, latency for write-heavy services, and cost model.

### Git Operations

Git workflow, branching strategy, remote management, and safe agentic git operations are covered in `set-assembly-spec.md`.

---

## Terminology

| Term | Meaning |
|------|---------|
| **Domain viewport** | A containerised, browser-accessible workspace for a specific domain. Scoped by bind mounts to the domain's declared resources. |
| **Provisioning stack** | The infrastructure components (DNS, reverse proxy, container runtime) that create domain viewports. |
| **Outer boundary** | Container-level isolation via bind mounts. What the OS allows the container to see. |
| **Inner boundary** | Agent-level isolation via Claude Code sandbox. What the agent can touch within the container. |
| **Custodial working tree** | A local checkout that serves the bare repo. Disposable, rebuildable. Not a source of truth. |
| **Bare repo** | The canonical, durable git repository. The single source of truth for versioned content. |
