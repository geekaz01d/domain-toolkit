---
name: touch-domain
description: "Universal domain kit management: structural validation, git precheck, profile regeneration, or new domain bootstrapping. Modal — inspects state and picks the right action."
argument-hint: "[--full | --new | --all | --no-touchy | -y] [domain-path]"
---

You are implementing the **`touch-domain`** command from `orchestrator-architecture.md`. This is the universal entry point for any domain interaction — modal, flag-driven, and extensible.

Read `orchestrator-architecture.md` (the `touch-domain` section and `Git Conventions` subsection) and `domain-convention.md` for canonical reference. Read the meta-domain's `domain.yaml` (`~/.claude/domain-toolkit/domain.yaml` or the repo's own `.claude/domain-toolkit/domain.yaml`) for `default_remote_pattern` — the installation-level default for bare repo creation.

## Argument Parsing

Parse `$ARGUMENTS` for flags and a path:

- **`--full`** — Full profile regeneration mode. **Requires a domain path** (or uses cwd). Does not sweep the registry — that's `--all`.
- **`--new`** — New domain bootstrapping mode
- **`--all`** — Sweep: run `--full` across every domain in the registry. **Expensive** — requires a model call per domain. Before executing, read the registry, count the domains, and warn the user: "This will run a full touch on N domains. Proceed?" Always prompt, even with `-y`. Respects `--no-touchy` (dry-run the sweep).
- **`--no-touchy`** — Read-only diagnostic (no writes). Composes with other modes.
- **`-y`** — Suppress prompts (auto-confirm safe git operations). Does NOT suppress the `--all` cost warning.
- The remaining non-flag argument is the **domain path** (relative or absolute). If absent, use the current working directory. Exception: `--new` with no path prompts for one; `--all` ignores the path and uses the registry.

Normalize the domain path to an absolute path before proceeding.

## Execution Order

Always follow this sequence:

1. **Parse arguments** (flags + path)
2. **Git precheck** (if domain path exists)
3. **Mode dispatch** (based on flags and state)
4. **Report** (summarize what was found/done)

## Step 1: Git Precheck

If the domain path exists, check its git state. This runs **before** any touch logic. Determine which of these 6 states applies:

| State | Condition | Action |
|-------|-----------|--------|
| **Diverged** | Local and remote have divergent commits | **Block all writes.** Surface the problem. Tell the user to resolve manually. Even `--full` and `--new` are blocked. |
| **Behind** | Remote is ahead of local | **Block all writes.** Prompt: "Canonical version is on the server. Pull first or work on the server copy?" |
| **Ahead** | Local has unpushed commits | **Proceed** with touch. Surface concern. Prompt to push (unless `-y`, which auto-confirms). |
| **Clean** | In sync with remote | **Proceed** normally. |
| **No remote** | `.git/` exists but no remote `origin` | **Proceed** with touch. Prompt to create bare remote per `default_remote_pattern` in the meta-domain's `domain.yaml` (unless `-y`, which auto-confirms). |
| **Not a repo** | No `.git/` directory | **Proceed** with touch. Prompt to initialize git (unless `-y`, which auto-confirms). |

**Implementation:** Use `git status`, `git remote -v`, `git rev-list --left-right --count HEAD...@{upstream}` (or similar) to determine the state. Handle missing upstream gracefully.

**`-y` auto-confirms** states: Ahead, No remote, Not a repo. **`-y` does NOT override** Diverged or Behind — those always block.

**`--no-touchy` skips** all prompts and writes but still reports the git state.

Also check and report:
- Uncommitted changes (staged or unstaged)
- Detached HEAD, mid-rebase, or merge conflict state
- Whether the remote matches `default_remote_pattern` from the meta-domain's `domain.yaml`

## Step 2: Mode Dispatch

### Default Mode (no `--full`, `--new`)

Smart touch. Inspect the target path and pick the right action:

1. **Path doesn't exist or has no `.context/`**: Tell the user "This doesn't exist as a domain. Create it with `touch-domain --new <path>`." Do not create anything.

2. **Path exists, `.context/` exists but PROFILE.md is missing or stale**: Run structural validation (see below). Suggest `touch-domain --full` to regenerate the profile.

3. **Path exists, `.context/` healthy**: Run structural validation only.

**Structural validation** (the core of default touch):
- `.context/` directory exists
- `.claude/domain-toolkit/domain.yaml` exists (detection signal, tracked in git)
- `persona.md` exists at domain root (agent identity, tracked in git)
- Required `.context/` files exist: `STATE.md`, `MEMORY.md`, `DECISIONS.md`, `PROFILE.md`
- `sessions/` directory exists
- Pointer integrity: if `persona.md` exists, check that any referenced files in its context map actually exist
- `domain.code-workspace` exists at domain root
- For any missing structural element: if `--no-touchy`, just report it. Otherwise, create minimal placeholder scaffolding per `domain-convention.md`.

**Staleness heuristic for PROFILE.md**: Compare PROFILE.md's modification time against MEMORY.md, DECISIONS.md, STATE.md, and README.md. If any source file is newer, PROFILE.md is considered stale.

### `--full` Mode

Everything default mode does, **plus** content synthesis:

1. Run structural validation (create scaffolding if needed, unless `--no-touchy`)
2. Read canonical context files: `README.md`, `domain.yaml`, `persona.md`, `STATE.md`, `MEMORY.md`, `DECISIONS.md`
3. Perform a **light scan** of the domain's repo/folder contents:
   - Focus on key files referenced in the canonical context
   - Sample directory structure (don't exhaustively read large trees)
4. **Regenerate `.context/PROFILE.md`**:
   - Summarize what the domain is and does
   - Key components, entry points, important files
   - Important decisions and constraints from DECISIONS.md
   - Current status and open threads from STATE.md
   - Gaps or missing pieces in canonical files
   - Header: `**Generated:** <date> (full touch)` and note that this is derived — edit source files instead
5. **Generate or update `domain.code-workspace`** at the domain root:
   - Two folders: domain root + `.context/` (named "Domain Context")
   - `folderOpen` task to open context files as tabs
   - Extension recommendation for `anthropic.claude-code`
6. Print a summary: domain root, timestamp, notable gaps or warnings

### `--new` Mode

New domain bootstrapping. The path may or may not exist yet.

1. If the path already has `.context/`, warn: "This already looks like a domain. Did you mean `touch-domain <path>` (default) or `touch-domain --full <path>`?"
2. Create the domain directory if it doesn't exist
3. **Begin interactive onboarding**: Ask the user about:
   - What is this domain? What does it contain?
   - What's its scope? Narrow or broad?
   - Agent persona and model tier preference
   - Initial concerns or priorities
4. From the onboarding conversation, create:
   - `.claude/domain-toolkit/domain.yaml` (manifest, detection signal) — tracked in git
   - `persona.md` (agent identity, model tier, context map) — tracked in git
   - `README.md` at domain root (from the user's description)
   - `.context/` directory with scaffolding (gitignored)
   - Initial `STATE.md`, `MEMORY.md` (minimal), `DECISIONS.md` (empty structure)
   - `sessions/`
5. Capture the onboarding conversation as the first session artifact in `.context/sessions/`
6. Initialize git:
   - `git init`
   - Prompt to create bare repo on the server per `default_remote_pattern` in the meta-domain's `domain.yaml` (unless `-y` auto-confirms)
   - Configure origin remote
   - Initial commit with scaffolding
7. Run `--full` logic to generate PROFILE.md and `domain.code-workspace`
8. Suggest opening the domain: `open-domain <domain> --cursor`

### `--all` Mode

Sweep the entire domain registry with `--full` touch on each domain.

1. Read `~/.claude/domain-toolkit/REGISTRY.yaml` to get the list of known domains
2. Count the domains and **always warn**: "This will run a full touch on N domains (model call per domain). Proceed?" This prompt is **never suppressed** — not by `-y`, not by automation. The user must confirm.
3. If confirmed, iterate through each domain and run `--full` logic on it
4. If `--no-touchy` is active, do a dry-run sweep: report what each domain's full touch would find, but write nothing
5. Summarize the sweep: domains touched, issues found, profiles regenerated

If no registry exists, tell the user: "No registry found. Create one with `add-domain --update` or seed `REGISTRY.yaml`."

### `--no-touchy` Modifier

Composes with any mode. Changes behavior:
- **No writes** — don't create files, don't scaffold, don't modify anything
- **No prompts** — don't ask about git operations
- **Full reporting** — report everything that *would* happen
- `--no-touchy` alone: report what default touch would find/fix
- `--full --no-touchy`: report what full touch would do (including what PROFILE.md regen would produce)
- `--new --no-touchy` on a nonexistent path: report what bootstrapping would create

## Step 3: Report

Summarize results in chat. Include:
- Domain root path
- Git state (which of the 6 states, plus any concerns)
- Mode that was executed
- What was found, created, or would be created (`--no-touchy`)
- Any warnings or suggestions for next steps
