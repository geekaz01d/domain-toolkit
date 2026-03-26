# Viewport Spec

**Status:** Draft — 2026-03-24
**Context:** Defines the viewport module system for `open-domain`. Replaces the flag-based viewport selection (`--cursor`, `--terminal`) with named viewport profiles defined as YAML files with command templates. Introduces the terminal layer as the default primitive, a profile discovery mechanism, and thin access declarations for containerised viewports.

---

## Design Principles

1. **The terminal layer is the default.** Every viewport bottoms out in a shell that can run `claude`. The bare terminal launch — `cd <path> && claude` — is the default viewport. Every other viewport wraps this via its command template.
2. **Viewports are named profiles, not flags.** `--viewport tmux`, not `--tmux`. Each viewport is a YAML file in `.claude/domain-toolkit/viewports/`. The filename is the name.
3. **Command templates, not hardcoded logic.** Viewport profiles contain shell command templates with placeholders. The skill substitutes and executes. Users can customise or add new viewports by editing or adding YAML files.
4. **Always explicit, optionally defaulted.** The command always accepts `--viewport`. Config stores a default. If neither, the terminal default applies.
5. **Declare access, don't fulfill it.** Container viewports need scoped access. domain-toolkit declares what access a domain needs (in domain.yaml). A deployment package fulfills it. domain-toolkit contains no provisioning logic.

---

## Command Syntax

```
open-domain <domain>                        # terminal default — runs in current shell
open-domain <domain> --viewport tmux        # named viewport from profile
open-domain <domain> --viewport cursor      # named viewport from profile
open-domain <domain> --viewport container   # named viewport from profile
```

**Viewport resolution order:**
1. Explicit `--viewport` argument (highest priority)
2. `default_viewport` from `~/.claude/domain-toolkit/config.yaml`
3. `terminal` (bare launch in current shell)

**Backward compatibility:** `--terminal` remains as an alias for `--viewport terminal` during transition. `--cursor` is retired — use `--viewport cursor` if needed.

---

## The Terminal Layer

The shared foundation. Every viewport consumes this layer — some ARE just this layer, others wrap its output.

### Responsibilities

1. **Resolve domain** — from name (via registry) or path to absolute domain root.
2. **Precheck** — `domain.yaml` exists, structural health.
3. **Build the claude launch string:**
   ```
   claude --append-system-prompt-file <domain-path>/persona.md
   ```
   Additional flags (e.g. `--session-id`) may be appended.

This launch string is the `{cmd}` placeholder available to all viewport templates.

### Default viewport (`terminal`)

When no `--viewport` is specified and no default is configured, the terminal layer runs the launch string directly in the current shell. This takes over the current terminal session — identical to the current `--terminal` behaviour.

There is no `terminal.yaml` profile file. The terminal default is implicit — it is the absence of a viewport profile. The skill runs the launch string directly when no viewport is selected.

---

## Viewport Profiles

### Location and Deployment

Viewport profiles live in `.claude/domain-toolkit/viewports/` in the repo. They are deployed to `~/.claude/domain-toolkit/viewports/` via `install-domain-toolkit`:

- `--link` mode: symlinked (default — git pull updates profiles)
- `--install` mode: copied (standalone deployment)

### Discovery

The command scans `~/.claude/domain-toolkit/viewports/` for `*.yaml` files. The filename minus extension is the viewport name. `tmux.yaml` → `--viewport tmux`.

### Profile Schema

```yaml
# Required fields
name: <string>                  # Display name (matches filename)
description: <string>           # One-line description

# Optional fields
type: <string>                  # Classification: ide, container (default: terminal)
requires: [<string>]            # Prechecks that must pass before launch

# Command templates — evaluated in order, first matching condition wins
templates:
  - condition: <string>         # When to use this template
    command: <string>           # Shell command with placeholders
    emulator: <bool>            # If true, wrap in terminal emulator (default: false)
```

### Placeholders

Available in command templates. The skill substitutes these before execution.

| Placeholder | Source | Notes |
|-------------|--------|-------|
| `{name}` | domain.yaml `name` field | Available to all viewports |
| `{path}` | Resolved absolute domain root | Available to all viewports |
| `{cmd}` | Claude launch string from terminal layer | Terminal-type viewports |
| `{workspace_file}` | `*.code-workspace` at domain root | IDE-type viewports |
| `{access_file}` | Temp file with serialised access declarations | Container viewports |

### Conditions

Evaluated in template order. First match wins. `default` always matches.

| Condition | True when |
|-----------|-----------|
| `in_tmux` | `$TMUX` environment variable is set |
| `in_screen` | `$STY` environment variable is set |
| `in_zellij` | `$ZELLIJ` environment variable is set |
| `default` | Always (fallback) |

### Emulator Wrapping

When a template sets `emulator: true`, the command is wrapped in the configured terminal emulator's launch syntax. For example, if `terminal.emulator` is `alacritty`:

```
alacritty -e <command>
```

The emulator preference is read from `~/.claude/domain-toolkit/config.yaml`. Known emulator invocation patterns:

| Emulator | Pattern |
|----------|---------|
| `alacritty` | `alacritty -e <command>` |
| `kitty` | `kitty <command>` |
| `wezterm` | `wezterm start -- <command>` |
| `gnome-terminal` | `gnome-terminal -- <command>` |

Default emulator: `alacritty`.

### Prechecks (`requires`)

Named prechecks that the skill validates before executing the template.

| Precheck | What it validates |
|----------|-------------------|
| `workspace_file` | `*.code-workspace` exists at domain root |
| `access_declarations` | domain.yaml has an `access` block |
| `deployment_package` | Deployment tooling is installed and reachable |

If a precheck fails, the skill reports the issue and suggests a fix. It does not proceed.

---

## Shipped Profiles

### `tmux.yaml`

```yaml
name: tmux
description: Terminal multiplexer session

templates:
  - condition: in_tmux
    command: tmux new-window -n "{name}" "cd {path} && {cmd}"

  - condition: default
    emulator: true
    command: tmux new-session -s "{name}" "cd {path} && {cmd}"
```

### `cursor.yaml`

```yaml
name: cursor
description: Cursor/VS Code IDE window
type: ide

requires:
  - workspace_file

templates:
  - condition: default
    command: cursor --new-window "{workspace_file}"
```

### `screen.yaml`

```yaml
name: screen
description: GNU Screen session

templates:
  - condition: in_screen
    command: screen -t "{name}" bash -c "cd {path} && {cmd}"

  - condition: default
    emulator: true
    command: screen -S "{name}" bash -c "cd {path} && {cmd}"
```

### `container.yaml`

```yaml
name: container
description: Containerised viewport with scoped access
type: container

requires:
  - access_declarations
  - deployment_package

templates:
  - condition: default
    command: domain-deploy provision "{name}" --access "{access_file}"
```

The container viewport is a stub. The `domain-deploy` command is provided by the deployment package, not domain-toolkit.

---

## Custom Viewports

Users and modules can register new viewport types by adding YAML files to the viewports directory. The command discovers them automatically on the next invocation.

Example: a user creates `~/.claude/domain-toolkit/viewports/zellij.yaml`:

```yaml
name: zellij
description: Zellij terminal workspace

templates:
  - condition: in_zellij
    command: zellij action new-tab --name "{name}" -- bash -c "cd {path} && {cmd}"

  - condition: default
    emulator: true
    command: zellij --session "{name}" -- bash -c "cd {path} && {cmd}"
```

This immediately makes `--viewport zellij` available.

---

## Access Declarations

How a domain declares what resources it needs for containerised work. These go in domain.yaml under a new `access` key. User-declared, preserved across updates.

### Schema

```yaml
# domain.yaml — access declarations
access:
  repos:
    - repo: cashflow              # Domain name or repo name
      mode: rw                    # rw | ro
    - repo: cashflow-imports
      mode: ro

  identity: richard               # User identity to bind in the container.
                                  # The deployment package resolves this to
                                  # SSH keys, git config, etc.

  mounts:                         # Additional bind mounts beyond repos
    - source: /mnt/user/data/finance
      target: /data/finance
      mode: ro
```

### What domain-toolkit does with these

Stores and surfaces them. `touch-domain` may validate structure (malformed YAML, missing subfields) but does not check whether declared repos exist or mounts are reachable. That is the deployment package's concern.

### What the deployment package does

Reads domain.yaml, extracts the `access` block, and:
- Assembles bind volume declarations for Docker
- Provisions SSH keys and git configuration for the declared identity
- Creates DNS entries and reverse proxy configuration
- Manages container lifecycle

This separation keeps domain-toolkit portable. A different deployment package could target a VPS, a cloud provider, or a local Docker setup. The access declarations are the stable interface.

---

## Config File

`~/.claude/domain-toolkit/config.yaml` — user preferences for viewport behaviour. Machine-specific, not synced via Syncthing.

### Schema

```yaml
default_viewport: tmux            # Used when --viewport is not specified
terminal:
  emulator: alacritty             # Used when a viewport template sets emulator: true
```

### Lifecycle

- **Not part of the install bundle.** The installer does not create or seed config.yaml. It is purely user-authored.
- **Preserved across install/uninstall.** Added to the preserved files list in `install-spec.md`.
- **Missing file is valid.** All config values have defaults (viewport: `terminal`, emulator: `alacritty`).
- **Not synced.** Terminal emulator preferences differ per machine.

---

## Skill Decomposition

With viewport logic moving into YAML profiles, `open-domain` becomes a natural candidate for phase decomposition. Proposed structure:

```
.claude/skills/open-domain/
  SKILL.md              # Gate: parse domain + --viewport, load profile, dispatch
  phases/
    terminal.md         # Default: bare launch in current shell
    profile.md          # Profile-based launch: load YAML, evaluate conditions, execute
  refs/
    terminal-layer.md   # Shared: domain resolution, prechecks, claude launch string
```

The gate classifies: no viewport → terminal phase. Viewport specified → profile phase (loads the YAML and executes). This is future work, not part of this spec.

---

## Relationship to Existing Specs

| Spec | Relationship |
|------|-------------|
| `command-taxonomy.md` | `open-domain` entry to be updated for `--viewport` syntax and profile-based dispatch. |
| `set-assembly-spec.md` | Set assembly is orthogonal to viewport type. A set can be opened in any viewport. |
| `storage-and-services.md` | The containerised viewport vision is the target for the `container` profile. Access declarations replace informal language with a concrete schema. |
| `domain-yaml-schema.md` | New `access` section to be added to the schema. User-declared, preserved. |
| `install-spec.md` | `viewports/` directory added to install bundle. `config.yaml` added to preserved files list. |

---

## Implementation Status

| Component | Status |
|-----------|--------|
| Terminal default (bare launch) | Implemented (phases/terminal.md) |
| `cursor` viewport | Implemented (profile: viewports/cursor.yaml) |
| `tmux` viewport | Implemented (profile: viewports/tmux.yaml) |
| `screen` viewport | Implemented (profile: viewports/screen.yaml) |
| `container` viewport | Profile defined (viewports/container.yaml). Depends on deployment package. |
| Viewport profile YAML schema | Implemented. 4 profiles shipped. |
| Profile discovery | Implemented in phases/profile.md |
| `--viewport` flag | Implemented. `--terminal` retained as alias. `--cursor` retired. |
| `config.yaml` | Not yet created. Defaults apply (viewport: terminal, emulator: alacritty). |
| Access declarations | Not implemented. domain.yaml schema extension pending. |
| Skill decomposition | Implemented (gate + 2 phases + 1 ref). |
