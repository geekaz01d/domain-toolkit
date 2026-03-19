# Set Assembly Spec

**Status:** Draft — captured from working session 2026-03-18
**Context:** Defines how domain sets are materialised as physical workspaces using git worktrees, and how they integrate with containerised domain viewports.

---

## Design Principles

1. **Sets are always derivatives.** Set assembly always uses git worktrees in a managed location. The original checkouts in `~/sources/` are untouched.
2. **Worktrees live in a dotfolder.** Assembled sets go in `~/.claude/domain-toolkit/worktrees/`, not loose in `~/sources/`. Clean separation between source repos and managed infrastructure.
3. **Folder structure is organisational, not semantic.** The fact that repos share a parent directory (e.g. `infrastructure/`) is a filesystem convenience, not a grouping mechanism. Sets are defined in the registry via domain.yaml. Folder co-location is irrelevant to set membership.
4. **Data integrity first.** Worktrees are disposable derivatives. The bare repo on fluffy is the source of truth. The original checkout in `~/sources/` is the primary working copy. Worktrees are the most disposable tier.
5. **Git first, docker second.** The worktree assembly creates the filesystem layout. Container bind volume assembly layers on top of it.
6. **Worktrees and branches are opt-in.** For individual domain work, you work directly in the canonical checkout. Worktrees are for set assembly or when you explicitly want a derivative (e.g. autonomous agent sessions, experiments).

---

## Three-Tier Disposability

| Tier | Location | Role | Disposability |
|------|----------|------|---------------|
| **Bare repo** | `fluffy:/mnt/user/git/<repo>.git/` | Source of truth | Durable. The canonical asset. |
| **Primary checkout** | `~/sources/<repo>` | Individual domain work | Custodial. Rebuildable from bare repo. |
| **Worktree** | `~/.claude/domain-toolkit/worktrees/<set>/<repo>` | Set-level work | Fully disposable. Tear down without losing anything. |

---

## Set Root

The **set root** is the top-level directory of an assembled set. It provides governance scoped to set-level work. It is not a domain — it has no MEMORY, DECISIONS, or distillation lifecycle by default. It is an orchestration scope.

The set root gets its own:

- `CLAUDE.md` — set-level project mechanics and governance
- `AGENTS.md` — set-level agent instructions (optional)
- `.claude/domain-toolkit/domain.yaml` — set manifest
- `persona.md` — set-level persona (optional, for set-level agent work)

**Contexts never mix.** The set root's `.context/` (if it exists) is about set-level coordination work. Each member worktree retains its own `CLAUDE.md`, `persona.md`, and `.context/` independently. An agent working at set level writes to the set root's context. An agent working inside a member writes to that member's context. There is no blending.

---

## Set Assembly

When `open-domain <set-name>` resolves to a set, it assembles the set as worktrees:

```
~/.claude/domain-toolkit/worktrees/
  infrastructure/                            # set root
    CLAUDE.md                                # set-level governance
    AGENTS.md                                # set-level agent instructions (optional)
    .claude/domain-toolkit/
      domain.yaml                            # set manifest
    persona.md                               # set-level persona (optional)
    systems-architectures/                   # git worktree → ~/sources/infrastructure/systems-architectures
      CLAUDE.md                              #   member's own governance (untouched)
      .context/                              #   member's own context (untouched)
    systems-geekazoid/                       # git worktree → ~/sources/infrastructure/systems-geekazoid
    systems-harrklen/                        # git worktree → ~/sources/infrastructure/systems-harrklen

  finance/                                   # another set root
    CLAUDE.md
    .claude/domain-toolkit/
      domain.yaml
    cashflow/                                # git worktree → ~/sources/cashflow
    claude-collect/                          # git worktree → ~/sources/claude-collect
```

Created by `open-domain`:

```bash
mkdir -p ~/.claude/domain-toolkit/worktrees/finance
cd ~/sources/cashflow
git worktree add ~/.claude/domain-toolkit/worktrees/finance/cashflow main
cd ~/sources/claude-collect
git worktree add ~/.claude/domain-toolkit/worktrees/finance/claude-collect main
```

Each worktree directory contains a `.git` **file** (not a directory) that points back to the original repo's `.git/`:

```
# .git file contents
gitdir: /home/richard/sources/cashflow/.git/worktrees/cashflow
```

The original repos stay where they are. The worktree assembly is a derivative view that groups them by set. You can add domains from anywhere — `~/sources/cashflow`, `~/sources/infrastructure/systems-geekazoid`, `~/sources/fluffy_sources/cursus` — into the same set. Folder co-location is irrelevant.

---

## Worktree Lifecycle

### Assemble

`open-domain <set-name>` resolves the set from the registry, creates worktrees for each member, and scaffolds set-level governance at the set root.

### Work

Work in worktrees as normal. Files are real. `git add`, `git commit`, `git push` all work. Commits go to the same object store as the original repo. Push from the worktree and it's on fluffy.

### Refresh

`git pull` in the worktree to bring it current with the bare repo. Since there's only one writer at a time, this is always a fast-forward. No merge conflicts.

### Tear Down

```bash
git worktree remove ~/.claude/domain-toolkit/worktrees/finance/cashflow
git worktree remove ~/.claude/domain-toolkit/worktrees/finance/claude-collect
rm -rf ~/.claude/domain-toolkit/worktrees/finance
```

The original repos in `~/sources/` are completely untouched. The bare repos on fluffy are untouched. Any committed work in the worktree is already in the object store and can be pushed/pulled from the original checkout.

---

## Set-Level Memory Anchoring (Opt-In)

By default, the set root has no `.context/`. It provides governance only. Work done inside member worktrees is attributed to those individual domains as normal.

When explicitly opted in, the set root gains its own `.context/` with MEMORY.md, DECISIONS.md, STATE.md, PROFILE.md, and sessions/. At this point the set root behaves like a domain in its own right — it has a knowledge layer, a distillation lifecycle, session history.

This is useful when:

- **Members are unequal.** A set includes third-party repos, client domains, or repos you don't control. You don't want to add domain-toolkit files to those members. All orchestration context lives at the set root.
- **The work is about the set, not the members.** Cross-cutting concerns, integration work, coordination tasks. The session notes and memory belong to the coordination effort, not to any individual member.

Even with set-level memory anchoring, **member contexts remain independent and untouched.** The set root's context is about the set-level work. Each member's context is about that member's work. They are never blended.

---

## Docker Integration

The worktree directory is the mount point for containerised viewports:

```yaml
volumes:
  - ~/.claude/domain-toolkit/worktrees/finance:/workspace:rw
```

The container sees a coherent workspace with all set members as subdirectories. Git first, docker second: the filesystem layout is established by worktree assembly. Container provisioning references the assembled path. The `open-domain` skill orchestrates both steps in sequence.

### Blast Radius Containment

The container operates on the derivative (worktree), not the original checkout. If an agent or process inside the container does something destructive:

- The worktree is damaged → tear down and reassemble. Zero data loss.
- The original checkout in `~/sources/` → untouched (outside the container's mount).
- The bare repo on fluffy → untouched (commits are the durable act).

---

## Local Claude Code (No Container)

When opening a set locally (no container viewport), `open-domain` opens the set root directory in the IDE (Cursor, VS Code). The worktree members are subdirectories. Claude Code launches in the set root.

The set root's `CLAUDE.md` provides project mechanics. The set root's `persona.md` provides the agent's role for set-level work. Individual member domains retain their own CLAUDE.md and persona.md for when work focuses on a single member.

---

## Branch Considerations

A git repo can only have one worktree per branch. If `cashflow` is checked out on `main` in `~/sources/cashflow`, the worktree cannot also be on `main`.

Options:

- **Detached HEAD**: `git worktree add --detach <path>`. The worktree starts at the same commit but isn't tracking a branch. Good for read-heavy or short-lived set work.
- **Set branch**: Create a lightweight branch for the worktree (e.g. `set/finance`). This gives the worktree its own branch that can diverge and merge back. Good for longer-lived set work.
- **Original moves**: Check out a different branch in the original, freeing `main` for the worktree. Only makes sense if you're not actively working in the original.

The default for `open-domain` should be detached HEAD (safest, most disposable). If the user needs a branch, they create one explicitly.
