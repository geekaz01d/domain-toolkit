# Rename Spec

**Status:** Draft — revised from working session 2026-03-20
**Context:** Defines how domains are renamed. Scoped to the domain label (the `name` field in domain.yaml). Storage reorganisation (directory, bare repo, remotes) is a separate concern, deferred. Implements the `rename-domain` entry in `command-taxonomy.md`.

---

## Why Rename Matters

Domain naming should be low stakes. When you first create a domain with `add-domain`, the name you pick is a best guess. As the domain matures, a better label emerges. You should be able to change it cleanly, without anxiety about breaking things.

`rename-domain` exists to make that relabelling safe and complete. It changes the domain's logical identity — the name everything else resolves by — and ensures the registry stays consistent.

---

## The Identity Model

A domain has two names that often — but don't have to — match:

### Domain Name (`name` field)

The **logical identity**. This is what you pass to `open-domain`, what appears as the key in the registry, what shows up in the sets index, and what other systems reference when they mean "this domain."

The domain name is **not tied to the filesystem**. A domain named `cashflow` might live at:
- `~/sources/cashflow` (primary checkout — name and directory happen to match)
- `~/sources/old-cashflow-name` (directory was never renamed after a prior identity change)
- `~/.claude/domain-toolkit/worktrees/finance/cashflow` (set worktree)
- Any arbitrary path

Worktrees make this explicit: the same domain can exist at multiple paths simultaneously, but it has one name. The directory basename is a convention, not a guarantee. The domain name is the durable, portable identity — it survives directory moves, worktree assembly, and machine-to-machine sync.

**Where the domain name appears:**
- `domain.yaml` `name` field (the source of truth)
- Registry `domains:` map (keyed by name — derived from domain.yaml)
- Registry `sets:` index (lists domain names as values — derived)
- Prose references in `.context/` files (MEMORY, STATE, PROFILE, session notes)

### Repo Name (`repo` field)

The **git identity**. This determines:
- Bare repo name on the server (e.g., `fluffy:/mnt/user/git/<repo>.git`)
- Remote URLs (contain the repo name)
- Conventional directory basename (by convention, not by rule)
- The `canonical_source` URL

The repo name is declared in domain.yaml and verified by `touch-domain` against the directory basename. A mismatch is surfaced as a concern, not an error — because worktrees, historical renames, and deliberate naming choices all create legitimate mismatches.

**Where the repo name appears:**
- `domain.yaml` `repo` field
- `domain.yaml` `canonical_source` (embedded in URL)
- `domain.yaml` `remotes` map (embedded in each URL)
- Actual git remote URLs in `.git/config`
- Bare repo directory name on the server
- Primary checkout directory basename (by convention)

### The Relationship Between Name and Repo

In the common case, `name == repo`. The domain `cashflow` lives in a repo called `cashflow`. Simple.

But they can diverge intentionally:
- A domain might be renamed logically (`cashflow` → `ledger`) while keeping the same repo for git history continuity
- An inherited or third-party repo might have a repo name that doesn't match the domain name the operator assigned

After a name-only rename, the domain is in a **workable but untidy state**: the name and repo differ, the directory doesn't match the name. This is valid. `touch-domain` surfaces the mismatch as a concern. The user can live with it indefinitely or tidy up later (see "Deferred: Storage Reorganisation" below).

---

## What rename-domain Does

`rename-domain` changes the domain label. That's it.

**What changes:**
- `domain.yaml` `name` field → new name
- Registry `domains:` map → re-keyed on rebuild (the name is the primary key)
- Registry `sets:` index → updated on rebuild (sets reference domain names)

**What does not change:**
- `repo` field, `canonical_source`, `remotes` — untouched
- Directory location — stays where it is
- Bare repo on server — untouched
- Git remote URLs — untouched
- `.context/` files — not machine-updated

---

## Pre-Flight Checks

Before presenting the change plan:

1. **Registry exists.** Read `~/.claude/domain-toolkit/REGISTRY.yaml`. If missing → error.
2. **Old name resolves.** Look up `<old-name>` in `domains:`. If not found → error.
3. **New name available.** Check `<new-name>` against both `domains:` and `sets:` maps. If taken → error: "Name `<new-name>` is already in use."
4. **domain.yaml accessible.** Read domain.yaml at the registered path. If missing → error (registry stale).
5. **Working tree clean.** No uncommitted changes. A rename in a dirty tree risks entangling the rename commit with unrelated work.

If the domain path is not a git repository, skip the clean-tree check. The rename still works without git — domain.yaml is updated and the registry rebuilds. The commit step is skipped gracefully (see Execution Order).

All pre-flight checks run before any changes. If any check fails, no changes are made.

---

## The Change Plan

After pre-flight, the command presents every change that will be made. The plan is always shown — mandatory, not opt-in. The user confirms before execution begins.

```
Rename plan:

  domain.yaml name:     <old-name> → <new-name>
  Registry:             re-keyed on rebuild

  Unchanged:
    repo:               <repo>
    directory:          <path>
    canonical_source:   <url>
    git remotes:        (unchanged)
```

With `--no-touchy`: display the plan and stop. "Dry run complete. No changes made."

---

## Execution Order

1. **Update domain.yaml** — change `name` field. Preserve all other fields, comments, and formatting.
2. **If git repo: commit** — `git add .claude/domain-toolkit/domain.yaml && git commit -m "Rename domain: <old> → <new>"`. If not a git repo, skip this step.
3. **Rebuild registry** — trigger `add-domain --update`. The old name disappears, the new name appears, because the registry is derived from domain.yaml files on disk.
4. **Report** — "Domain renamed: `<old>` → `<new>`. Registry updated." If commit was skipped, note: "No git repo — change is not committed."

If step 1 fails, no registry change occurs. If step 2 fails (git error), warn but continue to step 3 — the domain.yaml is already updated, and the registry should reflect it.

---

## User Confusion: "I Already Renamed the Directory"

A user who renamed their directory (`mv ~/sources/tomato ~/sources/potato`) might reach for `rename-domain` expecting it to reconcile the storage side. It won't — it changes the label.

The command should detect this situation. If the user runs `rename-domain tomato potato` and the directory basename is already `potato`, surface guidance: "It looks like you've already renamed the directory. `rename-domain` changes the domain's logical name. If you want the domain name to match, this will do that."

Conversely, if the user does a name-only rename and the name now differs from the directory, note: "`touch-domain` will surface the name/directory mismatch. The domain is fully workable in this state."

---

## What rename-domain Does NOT Do

These are explicit boundaries.

### Does not rename storage

Directory, bare repo, remote URLs, and `repo` field are untouched. This is a separate concern (see below).

### Does not update prose references

MEMORY.md, STATE.md, PROFILE.md, session notes, and other prose files may reference the old domain name. These are not machine-updated. The distiller and human address them over time as they encounter them.

### Does not rename set names

If a set happens to share the old domain name, it is not renamed. Sets are independent identifiers managed by `group-domain`.

### Does not reconfigure Syncthing

No storage moves, so no Syncthing impact.

---

## Relationship to Other Commands

| Command | Relationship |
|---------|-------------|
| **`touch-domain`** | Surfaces `name != repo` and `name != directory basename` as concerns. The diagnostic tool for post-rename state. |
| **`add-domain --update`** | Triggered by rename to rebuild the registry. Also responsible for resilience to filesystem changes (directory renames, worktree detection). |
| **`group-domain`** | Set membership transfers automatically — sets reference domain names, and the registry rebuild picks up the new name from domain.yaml. |
| **`open-domain`** | After rename, use the new name. The old name no longer resolves. |
| **`distill-domain`** | After rename, distill by the new name. Session history in `.context/sessions/` is unaffected. |

---

## Deferred: Storage Reorganisation

After a name-only rename, the user may want to align storage to match: rename the directory, the bare repo, the remote URLs, and the `repo` field in domain.yaml. This is a legitimate need but a separate concern from domain identity.

Storage reorganisation is more complex than relabelling:
- The repo name, directory name, and bare repo name could each have reasons to differ
- The user might want to rename the repo to something other than the domain name
- Bare repo renames require SSH access to the server
- Directory renames break Syncthing folder configuration
- Directory renames break existing worktrees (disposable, but still disruptive)
- Hosted remotes (GitHub, Gitea) require their own rename operations

This needs its own design work. It may be a separate command, an option on an existing command, or a guided pipeline. The key insight: rename-domain handles the identity, touch-domain surfaces the inconsistency, and the storage concern is resolved when the user is ready — not forced at rename time.

---

## Design Note: add-domain and Worktrees

`add-domain --update` scans disk for domain.yaml files to build the registry. Because domain.yaml is git-tracked, it appears in worktrees too. The scan must distinguish primary checkouts from worktrees to avoid double-counting.

The signal is in git: a primary checkout has a `.git/` **directory**; a worktree has a `.git` **file** pointing back to the primary. `add-domain` should check this during scan — if `.git` is a file, it's a derivative.

Whether worktrees should appear in the registry (as addressable entities) is a separate design question related to set assembly and long-lived worktrees. See the set-assembly spec for context. For rename-domain's purposes, only the primary checkout matters — the name change propagates to worktrees via git (domain.yaml is tracked).

---

## Superseded

This spec supersedes the stub definition of `rename-domain` in `command-taxonomy.md` (which previously said "Not yet fully specified"). The command-taxonomy entry should now reference this spec.
