# Install Spec

**Status:** Draft — expanded 2026-03-22, revised 2026-03-25 (viewport profiles, config.yaml)
**Context:** Defines the installation lifecycle for the domain-toolkit runtime on a machine. Covers deployment, symlink-based development installs, validation, and clean removal. Implements the `install-domain-toolkit` entry in `command-taxonomy.md`.

---

## Why an Installer

The domain-toolkit runtime depends on files deployed outside the repo — hooks in `~/.claude/domain-toolkit/`, wrappers in `~/.claude/hooks/`, and registrations in `~/.claude/settings.json`. Currently this is manual: copy files, set permissions, hand-edit JSON. It's error-prone, hard to verify, and there's no way to check what's installed or whether it's current.

`install-domain-toolkit` makes this a single, repeatable operation. It also gives the user a transparent picture of their installation state — what's there, what's missing, what's outdated.

---

## Dual Implementation

The installer has two forms:

**Shell script** (`.claude/domain-toolkit/bin/install-domain-toolkit`) — the primary implementation. This is the entrypoint for a new user who has just `git clone`'d the repo. It works before any skills are installed.

**Claude Code skill** (`.claude/skills/install-domain-toolkit/SKILL.md`) — delegates to the shell script. For existing users who prefer to work through the agent.

Both produce the same result. The shell script is authoritative.

---

## Modes

| Mode | Flag | What it does |
|------|------|-------------|
| Status | `--status` (default) | Transparent, detailed read-only report of everything installed |
| Install | `--install` | Full copy deployment from repo to `~/.claude/domain-toolkit/` |
| Link | `--link` | Symlink deployment — `git pull` instantly updates the runtime |
| Uninstall | `--uninstall` | Clean removal, leave no trace (except user data) |

Modifier: `--cron` — opt-in, composable with install/link/uninstall. Manages crontab entries from templates. Never auto-installed.

**Recommended path:** `--link` for developers working from a repo checkout. Symlinks mean `git pull` instantly updates the live runtime — no reinstall step. `--install` (copy) is for deploying to machines without a persistent checkout.

---

## The Bundle Manifest

The authoritative list of what gets installed. This is the source of truth for install, status, and uninstall.

### Deployed files

Source paths are relative to repo `.claude/domain-toolkit/`. Target paths are relative to `~/.claude/domain-toolkit/`.

| Source | Target | Executable |
|--------|--------|------------|
| `hooks/session-start.sh` | `hooks/session-start.sh` | yes |
| `hooks/session-end.sh` | `hooks/session-end.sh` | yes |
| `bin/open-domain` | `bin/open-domain` | yes |
| `bin/stage-transcripts` | `bin/stage-transcripts` | yes |
| `bin/install-domain-toolkit` | `bin/install-domain-toolkit` | yes |
| `cron/distill.cron` | `cron/distill.cron` | no |
| `cron/stage-transcripts.cron` | `cron/stage-transcripts.cron` | no |
| `domain.yaml` | `domain.yaml` | no |
| `REGISTRY.example.yaml` | `REGISTRY.example.yaml` | no |
| `viewports/tmux.yaml` | `viewports/tmux.yaml` | no |
| `viewports/cursor.yaml` | `viewports/cursor.yaml` | no |
| `viewports/screen.yaml` | `viewports/screen.yaml` | no |
| `viewports/container.yaml` | `viewports/container.yaml` | no |

### Generated files

| Target | Content |
|--------|---------|
| `~/.claude/hooks/session-start.sh` | `#!/bin/bash`<br>`exec "$HOME/.claude/domain-toolkit/hooks/session-start.sh"` |
| `~/.claude/hooks/session-end.sh` | `#!/bin/bash`<br>`exec "$HOME/.claude/domain-toolkit/hooks/session-end.sh"` |
| `~/.claude/domain-toolkit/.install-mode` | YAML: `mode`, `source`, `installed` |

### Shell integration

| Target | Content | Condition |
|--------|---------|-----------|
| `~/.bashrc` | `export PATH="$HOME/.claude/domain-toolkit/bin:$PATH"` | Appended if not already present |

The PATH entry makes `open-domain`, `stage-transcripts`, and `install-domain-toolkit` available as shell commands. Works identically in copy and link mode — the PATH points to the install target, not the repo.

Uninstall removes the PATH line (and its comment) from `~/.bashrc`. The user must open a new shell or `source ~/.bashrc` for changes to take effect.

### Preserved files (never touched)

| Path | Reason |
|------|--------|
| `~/.claude/domain-toolkit/REGISTRY.yaml` | User data — accumulated domain registrations |
| `~/.claude/domain-toolkit/config.yaml` | User configuration — viewport defaults, terminal emulator, deployment provider |
| `~/.claude/domain-toolkit/*.log` | Runtime logs |
| `~/.claude/domain-toolkit/.harvest-log` | Memory harvest log |
| `~/.claude/domain-toolkit/.staged-sessions` | Transcript staging state |

### Seeded once

| Target | Source | Condition |
|--------|--------|-----------|
| `~/.claude/domain-toolkit/REGISTRY.yaml` | `REGISTRY.example.yaml` | Only if absent |

---

## The Three-Layer Hook Chain

The hook system uses three layers of indirection. This architecture is preserved in all install modes.

```
Layer 1: Registration
  ~/.claude/settings.json → references ~/.claude/hooks/*.sh

Layer 2: Delegation
  ~/.claude/hooks/session-start.sh → exec ~/.claude/domain-toolkit/hooks/session-start.sh
  ~/.claude/hooks/session-end.sh  → exec ~/.claude/domain-toolkit/hooks/session-end.sh

Layer 3: Implementation
  ~/.claude/domain-toolkit/hooks/session-start.sh  (real file or symlink)
  ~/.claude/domain-toolkit/hooks/session-end.sh   (real file or symlink)
```

**Why three layers?** The registration (settings.json) and wrappers never change after initial install. Only the implementation layer changes — by copying new versions or by pointing symlinks at the repo. This means runtime updates don't require touching settings.json or regenerating wrappers.

In **copy mode**, layer 3 contains real files (copies from the repo).
In **link mode**, layer 3 contains symlinks to the repo checkout.

---

## The .install-mode Marker

A YAML file at `~/.claude/domain-toolkit/.install-mode` records installation metadata. Created by install, read by status, removed by uninstall.

```yaml
mode: link          # "copy" or "link"
source: /home/richard/sources/domain-toolkit
installed: 2026-03-22T14:30:00Z
```

`source` is the absolute path to the repo checkout at install time. In link mode, this is where symlinks point. In copy mode, this is where files were copied from (useful for staleness comparison).

---

## Environment Pre-Checks

Run before any mode. Severity determines whether we proceed or stop.

| Check | How | Severity |
|-------|-----|----------|
| Repo detection | `.claude/domain-toolkit/domain.yaml` exists with `name: domain-toolkit` | Error — stop |
| Bundle integrity | All source files in the manifest exist | Error — stop |
| Python3 | `command -v python3` | Warning — hooks need it at runtime |
| Claude Code CLI | `command -v claude` | Warning — hooks won't fire without it |
| Working tree | `git diff --name-only` on bundle files | Warning — installed copy reflects working tree, not last commit |

Pre-checks for `--status` mode are lighter: only repo detection and bundle integrity. No warnings about uncommitted changes for a read-only operation.

---

## Mode: Status (default)

The primary UX surface. Transparency is the design goal — the user sees a complete, honest picture of what's on their machine.

### Output structure

```
domain-toolkit runtime status
==============================

Mode:       link
Source:     /home/richard/sources/domain-toolkit
Installed:  2026-03-22T14:30:00Z

Runtime files (~/.claude/domain-toolkit/):
  hooks/session-start.sh    linked → <repo>/...  ✓
  hooks/session-end.sh      linked → <repo>/...  ✓
  bin/open-domain            linked → <repo>/...  ✓
  bin/stage-transcripts      linked → <repo>/...  ✓
  bin/install-domain-toolkit linked → <repo>/...  ✓
  cron/distill.cron          linked → <repo>/...  ✓
  cron/stage-transcripts.cron linked → <repo>/... ✓
  domain.yaml                linked → <repo>/...  ✓
  REGISTRY.example.yaml      linked → <repo>/...  ✓

Hook wrappers (~/.claude/hooks/):
  session-start.sh           present, executable, delegates correctly  ✓
  session-end.sh             present, executable, delegates correctly  ✓

Hook registration (~/.claude/settings.json):
  SessionStart               registered (timeout: 10s)   ✓
  SessionEnd                 registered (async: true)     ✓

PATH (~/.bashrc):
  domain-toolkit bin directory in PATH                    ✓

User data (preserved across install/uninstall):
  REGISTRY.yaml              present (7 domains)
  stage-transcripts.log      present (1.6K)

Skills (available in domain-toolkit repo):
  touch-domain               .claude/skills/touch-domain/SKILL.md
  add-domain                 .claude/skills/add-domain/SKILL.md
  ...

Cron:
  stage-transcripts          not installed (template available)
  distill                    not installed (template available)

Environment:
  claude CLI                 /usr/local/bin/claude          ✓
  python3                    /usr/bin/python3 (3.12.3)      ✓

Verdict: Installed (link mode), healthy
```

### Copy mode variations

For copy mode, instead of "linked →", report freshness:

```
  hooks/session-start.sh    installed, current              ✓
  hooks/session-start.sh    installed, outdated (repo newer) ⚠
```

Freshness is determined by comparing SHA256 hashes of installed file vs repo source.

### Broken states

Report exactly what's wrong:

```
  hooks/session-start.sh    MISSING                         ✗
  bin/open-domain            dangling symlink                ✗
  bin/stage-transcripts      not executable                  ⚠
```

### Verdict categories

| Verdict | Meaning |
|---------|---------|
| Not installed | Nothing present — no `.install-mode`, no bundle files |
| Installed (copy mode), current | All files match repo source |
| Installed (copy mode), outdated | Some files differ from repo source |
| Installed (link mode), healthy | All symlinks resolve |
| Installed (link mode), broken | Dangling symlinks detected |
| Partial install | Some pieces present, some missing, or missing `.install-mode` |

---

## Mode: Install (`--install`)

Full copy deployment.

### Steps

1. Run environment pre-checks.
2. Run status check internally to understand current state.
3. If switching from link mode, note: "Switching from link mode to copy mode."
4. Present the installation plan:
   - Files to copy (with paths)
   - Wrappers to generate
   - settings.json changes
   - What will be preserved
5. **Ask for confirmation.** Always.
6. Execute:
   a. Create directories: `~/.claude/domain-toolkit/{hooks,bin,cron,viewports}`, `~/.claude/hooks/`
   b. If switching from link mode, remove existing symlinks first.
   c. Copy each bundle file. Set executable bit where specified.
   d. Seed `REGISTRY.yaml` from `REGISTRY.example.yaml` if absent.
   e. Write `.install-mode` marker.
   f. Generate wrapper scripts. Set executable.
   g. Merge hook registrations into settings.json.
   h. Add `~/.claude/domain-toolkit/bin` to PATH in `~/.bashrc` (if not already present).
7. Run post-install validation.
8. Report results.

---

## Mode: Link (`--link`)

Symlink-based development install. Same flow as `--install` with these differences:

- Step 6b: If switching from copy mode, remove existing copies first.
- Step 6c: Create symlinks instead of copies. Each symlink at `~/.claude/domain-toolkit/<path>` points to `<repo>/.claude/domain-toolkit/<path>` (absolute paths).
- Step 6e: Write `.install-mode` with `mode: link`.
- Step 7: Validation additionally confirms all symlinks resolve.

Everything else — wrappers, settings.json merge, REGISTRY seed, confirmation — is identical to install mode.

### Tradeoff

Link mode means `git pull` updates the runtime instantly. The tradeoff: if the repo checkout moves or is deleted, symlinks dangle and the runtime breaks. `--status` detects and reports this.

---

## Mode: Uninstall (`--uninstall`)

Clean removal.

### Steps

1. Run status check to understand current state.
2. If nothing installed: "Nothing to uninstall." Exit.
3. Present the removal plan:
   - Bundle files to remove
   - Wrappers to remove
   - settings.json entries to remove
   - What will be preserved (with reasons)
4. **Ask for confirmation.** Always.
5. Execute:
   a. Remove bundle files (or symlinks) from `~/.claude/domain-toolkit/`.
   b. Remove `.install-mode`.
   c. Remove empty subdirectories (`hooks/`, `bin/`, `cron/`).
   d. Remove wrapper scripts from `~/.claude/hooks/`.
   e. Remove domain-toolkit hook entries from settings.json (see merge strategy).
   f. Remove PATH entry from `~/.bashrc`.
   g. If `~/.claude/domain-toolkit/` is now empty, remove it. If only preserved files remain, leave it.
6. If `--cron` also specified, remove domain-toolkit crontab entries.
7. Report what was removed and what was preserved.

---

## Modifier: `--cron`

Opt-in. Composable with `--install`, `--link`, or `--uninstall`. If used alone, operates on an existing install.

### Install

1. Read cron templates from `~/.claude/domain-toolkit/cron/` (installed) or repo (if not yet installed).
2. Perform variable substitution: `__TOOLKIT_ROOT__` → `~/.claude/domain-toolkit`, `__HOME__` → actual `$HOME`.
3. Check current crontab for existing domain-toolkit entries (match by command path).
4. Present what will be added.
5. Ask for confirmation.
6. Append to crontab (never replace existing entries).

### Uninstall

Match and remove domain-toolkit entries from crontab by command path.

### Status

Report whether domain-toolkit cron entries are present in the active crontab.

---

## settings.json Merge Strategy

The installer reads, modifies, and writes `~/.claude/settings.json`. It must handle all edge cases without clobbering other tools' settings.

### Install / Link

| Current state | Action |
|---------------|--------|
| File missing | Create with hooks section only |
| File exists, no `hooks` key | Add `hooks` with both events |
| `hooks` exists, no `SessionStart` or `SessionEnd` | Add the missing event entries |
| Event exists, domain-toolkit hook already present | Skip (match by command path) |
| Event exists, domain-toolkit hook absent | Append to the hooks array |
| File is invalid JSON | Error — refuse to modify, tell user to fix |

The matching key is the command string: `"$HOME"/.claude/hooks/session-start.sh` (and `session-end.sh`).

### Hook registration format

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "\"$HOME\"/.claude/hooks/session-start.sh",
        "timeout": 10
      }]
    }],
    "SessionEnd": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "\"$HOME\"/.claude/hooks/session-end.sh",
        "async": true
      }]
    }]
  }
}
```

### Uninstall

Remove only the array entries whose `command` matches the domain-toolkit wrapper paths. If a `SessionStart`/`SessionEnd` array becomes empty, remove the event key. If `hooks` becomes empty, remove it. Leave all other settings intact.

### Implementation

Use `python3 -c '...'` for JSON manipulation. `jq` is not guaranteed to be present.

---

## Update Model

### Link mode (recommended)

Updates are automatic. Symlinks point to the repo checkout. Running `git pull` in the repo immediately updates every file in the runtime — hooks, binaries, cron templates, everything.

The installer deploys itself (`bin/install-domain-toolkit` is in the bundle), so even the installer stays current via `git pull`.

### Copy mode

`--status` detects staleness by comparing SHA256 hashes of installed files against repo source files. Reports "outdated (repo is newer)" with the original install timestamp for context.

To update: run `install-domain-toolkit --install` again from the repo. The install is idempotent — it overwrites bundle files, preserves user data, and leaves settings.json entries intact if already correct.

**Important:** Always run the installer from the repo, not the installed copy. The repo version is authoritative.

---

## Preservation Rules

| Category | Files | Install | Uninstall |
|----------|-------|---------|-----------|
| Bundle files | hooks, bin, cron, domain.yaml, REGISTRY.example.yaml | Overwritten | Removed |
| Generated files | wrappers, .install-mode | Regenerated | Removed |
| User data | REGISTRY.yaml | Seeded if absent, never overwritten | Preserved |
| Runtime state | *.log, .harvest-log, .staged-sessions | Never touched | Preserved |
| Other | Any file not in the manifest | Never touched | Preserved |

---

## Post-Install Validation

Run automatically after install or link. Reports pass/fail for each check.

| Check | What it verifies |
|-------|-----------------|
| Files exist | All target files present and non-empty |
| Executability | Hook and bin scripts have execute permission |
| Symlink resolution | (Link mode) All symlinks point to valid targets |
| Wrapper content | Each wrapper contains the expected `exec` delegation line |
| settings.json validity | File parses as valid JSON |
| Hook registration | Expected entries present in settings.json |
| Python3 available | `python3` invocable (needed by hooks at runtime) |

---

## Error Handling

| Condition | Severity | Response |
|-----------|----------|----------|
| Not in domain-toolkit repo | Error | "Run this from within the domain-toolkit repo checkout." |
| Bundle files missing from repo | Error | "Bundle incomplete. Missing: [list]. Check repo state." |
| settings.json invalid JSON | Error | "~/.claude/settings.json is not valid JSON. Fix manually before installing." |
| python3 not found | Warning | "python3 not found. Hooks and stage-transcripts require Python 3 at runtime." |
| claude CLI not found | Warning | "Claude Code CLI not found. Hooks will be deployed but won't fire until Claude is available." |
| Uncommitted bundle changes | Warning | "Working tree has uncommitted changes to bundle files. Installed copy will reflect the working tree." |
| Switching install modes | Info | "Switching from [copy/link] to [link/copy] mode." |
| Dangling symlinks (status) | Error | "Dangling symlink: [path]. Repo checkout may have moved." |
| Write permission denied | Error | "Cannot write to [path]. Check permissions." |

---

## Relationship to Other Commands

| Command | Relationship |
|---------|-------------|
| **`touch-domain`** | Independent concern. Install sets up the machine-level runtime. touch-domain validates individual domains within that runtime. |
| **`add-domain`** | Composes forward. After install, the user runs `add-domain` to register domains and build `REGISTRY.yaml`. |
| **`open-domain`** | Depends on install for the `bin/open-domain` binary and hook chain. |
| **`distill-domain`** | Depends on install for `bin/stage-transcripts` and cron templates. |

---

## Superseded

This spec supersedes the seed spec captured 2026-03-19. The `install-domain-toolkit` entry in `command-taxonomy.md` should reference this spec.
