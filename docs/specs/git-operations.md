# Git Operations

**Status:** Draft — captured from working session 2026-03-18
**Context:** Defines git conventions, workflow, and safety model for domain-toolkit managed domains. Consolidates decisions made across domain-model-semantics, storage-and-services, set-assembly, and domain-yaml-schema specs.

---

## Source of Truth

The **bare repo on fluffy** (`fluffy.geekazoid.net:/mnt/user/git/<repo>.git/`) is the canonical source of truth for all versioned content. Everything else is a derivative.

---

## Three-Tier Disposability

| Tier | Location | Role | Disposability |
|------|----------|------|---------------|
| **Bare repo** | `fluffy:/mnt/user/git/<repo>.git/` | Source of truth | Durable. The canonical asset. Never directly modified. |
| **Primary checkout** | `~/sources/<repo>` (laptop or fluffy) | Individual domain work | Custodial. Rebuildable from bare repo at any time. |
| **Worktree** | `~/.claude/domain-toolkit/worktrees/<set>/<repo>` | Set assembly, derivatives | Fully disposable. Tear down without losing anything. |

---

## Sync Model

### Git Content

- **Push/pull is the only sync mechanism.** No Syncthing, no custom tooling for git-tracked content.
- **Single writer at a time.** There is no realistic scenario where both the laptop and the server have concurrent uncommitted changes to the same repo.
- **Working trees are custodial.** They exist to serve the bare repo. A stale working tree is a pull away from current. A corrupted working tree is a re-clone away from clean.

### Domain-Toolkit Overlay

Syncthing syncs the domain-toolkit overlay (CLAUDE.md, AGENTS.md, .claude/, .context/) per domain across viewport nodes. This content is gitignored. See `storage-and-services.md` for details.

Syncthing never syncs across branches. Branch content is a git concern.

---

## Branching

### Default Branch

Each domain declares its `default_branch` in `domain.yaml`. Typically `main`.

### Segmentation Branches

Branches handle visibility segmentation. A domain may have a `public` branch for open-source distribution while keeping its working branch private (e.g. domain-toolkit's `public` branch tracking `github/main`).

### Worktree Branches

Git worktrees require a unique branch per worktree. When assembling a set:

- **Default: detached HEAD.** Safest, most disposable. The worktree starts at the same commit as the primary checkout but isn't tracking a branch.
- **Set branch** (e.g. `set/finance`). For longer-lived set work. Can diverge and merge back.
- **Original moves.** Check out a different branch in the primary checkout, freeing the default branch for the worktree. Only when you're not actively working in the primary checkout.

Merging worktree branches back is a standard git merge operation.

---

## Remote Configuration

Each domain declares its remotes in `domain.yaml`:

```yaml
canonical_source: fluffy.geekazoid.net:/mnt/user/git/cashflow.git
default_branch: main
remotes:
  fluffy: fluffy.geekazoid.net:/mnt/user/git/cashflow.git
  github: git@github.com:geekaz01d/cashflow.git
```

`touch-domain` verifies actual git remotes against declared remotes and flags discrepancies. An agent repairing a broken checkout can reconstruct the remote configuration from domain.yaml.

---

## Custodial Checklist (`touch-domain`)

On domain entry, `touch-domain` surfaces git-relevant concerns:

- **Working tree clean?** Uncommitted changes (staged or unstaged).
- **Up to date?** Unpushed commits, behind remote.
- **Remote reachable?** Can the bare repo on fluffy be contacted?
- **Branches with unpushed work?** Any local branches ahead of their tracking branches.
- **Remote match?** Do actual git remotes match `domain.yaml` declarations?
- **Repo name match?** Does directory basename match `domain.yaml` `repo` field?
- **Detached HEAD or mid-rebase?** Unusual git states surfaced as concerns.

These are **surfaced as concerns, not silently fixed.** The human decides what to do. The exceptions (with `-y` flag) are:

- Auto-confirm push when Ahead
- Auto-confirm remote creation when No Remote
- Auto-confirm git init when Not a Repo

Diverged and Behind states **always block writes**, even with `-y`.

---

## Agentic Git Operations

### Principles

- **The commit is the durable act.** Working tree state between commits is ephemeral. Agents should commit meaningful checkpoints.
- **Agents are assistive.** They can detect drift, propose changes, and execute git operations. But humans approve destructive or ambiguous operations.
- **Prefer pipelines over syntax hunting.** Git operations should be well-tested Python functions or shell scripts, not ad-hoc bash assembled at runtime.

### What Agents Can Do

- Commit with meaningful messages (always prompted or explicit)
- Push to declared remotes
- Pull from declared remotes (fast-forward only)
- Create and remove worktrees
- Report git status, log, diff
- Surface custodial concerns

### What Agents Should Not Do Without Explicit Approval

- Force push
- Rebase
- Reset (hard or mixed)
- Delete branches
- Modify remote configuration
- Resolve merge conflicts

---

## Git Recovery

If a working tree is lost, corrupted, or needs to be rebuilt:

1. Read `domain.yaml` for `canonical_source` and `remotes`
2. Clone from `canonical_source`
3. Configure remotes per `domain.yaml`
4. Syncthing will populate the overlay (CLAUDE.md, AGENTS.md, .claude/, .context/) once the directory exists

The domain's knowledge layer (sessions, memory, decisions) is preserved in Syncthing. The domain's versioned content is preserved in the bare repo. A full recovery requires only a clone and a Syncthing sync.
