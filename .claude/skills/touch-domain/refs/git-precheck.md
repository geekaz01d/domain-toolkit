# Git Precheck

Run this before any mode-specific work.

## Non-git domains

Check whether the domain path is a git repository. If `.git/` does not exist (as a directory or file), this domain is **not git-managed**. Report: "Not a git repository -- skipping git precheck." Proceed directly to mode-specific work. Do not prompt to initialize git here -- that's `--new`'s job if the user is bootstrapping.

## Git state classification

If the domain **is** a git repo, determine which of these 5 states applies:

| State | Condition | Action |
|-------|-----------|--------|
| **Diverged** | Local and remote have divergent commits | **Block all writes.** Surface the problem. Tell the user to resolve manually. Even `--full` and `--new` are blocked. |
| **Behind** | Remote is ahead of local | **Block all writes.** Prompt: "Canonical version is on the server. Pull first or work on the server copy?" |
| **Ahead** | Local has unpushed commits | **Proceed** with touch. Surface concern. Prompt to push (unless `-y`, which auto-confirms). |
| **Clean** | In sync with remote | **Proceed** normally. |
| **No remote** | `.git/` exists but no remote `origin` | **Proceed** with touch. Prompt to create bare remote per `default_remote_pattern` in the meta-domain's `domain.yaml` (unless `-y`, which auto-confirms). |

**Implementation:** Use `git status`, `git remote -v`, `git rev-list --left-right --count HEAD...@{upstream}` (or similar) to determine the state. Handle missing upstream gracefully.

## Flag interactions

- **`-y` auto-confirms** states: Ahead, No remote. **`-y` does NOT override** Diverged or Behind -- those always block.
- **`--no-touchy` skips** all prompts and writes but still reports the git state (or the absence of git).

## Additional checks (git repos only)

Also check and report:
- Uncommitted changes (staged or unstaged)
- Detached HEAD, mid-rebase, or merge conflict state
- Whether the remote matches `default_remote_pattern` from the meta-domain's `domain.yaml`

Read the meta-domain's `domain.yaml` (`~/.claude/domain-toolkit/domain.yaml` or the repo's own `.claude/domain-toolkit/domain.yaml`) for `default_remote_pattern`.
