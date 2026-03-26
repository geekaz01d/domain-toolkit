# open-domain: Profile Mode

You are launching a domain using a named viewport profile.

## Step 1: Terminal Layer

Read `refs/terminal-layer.md` and run all three steps: resolve domain, prechecks, build launch string.

## Step 2: Load Viewport Profile

The viewport name was determined by the gate. Load the profile YAML from:

```
~/.claude/domain-toolkit/viewports/{viewport-name}.yaml
```

If the file does not exist: "Viewport profile `{viewport-name}` not found. Available profiles:" then list `*.yaml` files in the viewports directory (filenames minus `.yaml`). Stop.

Parse the profile. Required fields: `name`, `description`, `templates` (at least one entry).

## Step 3: Run Prechecks

If the profile has a `requires` list, validate each named precheck:

| Precheck | Validation |
|----------|-----------|
| `workspace_file` | A `*.code-workspace` file exists at the domain root. If missing: "No workspace file. Run `/touch-domain --full {path}` to generate one." |
| `access_declarations` | domain.yaml contains an `access` block. If missing: "No access declarations in domain.yaml. Container viewports require an `access` block." |
| `deployment_package` | The `domain-deploy` command is available on `$PATH`, or `deployment.provider` is set in `~/.claude/domain-toolkit/config.yaml`. If neither: "No deployment tooling found. Install the deployment package first." |

If any precheck fails, report the issue and stop. Do not proceed.

## Step 4: Evaluate Conditions

Walk the `templates` list in order. For each entry, evaluate its `condition`:

| Condition | True when |
|-----------|-----------|
| `in_tmux` | `$TMUX` environment variable is set |
| `in_screen` | `$STY` environment variable is set |
| `in_zellij` | `$ZELLIJ` environment variable is set |
| `default` | Always (fallback) |

Use the **first matching** template.

If no template matches (all conditions failed and no `default`): "No matching template condition for viewport `{viewport-name}` in this environment." Stop.

## Step 5: Substitute Placeholders

In the matched template's `command` string, replace:

| Placeholder | Value |
|-------------|-------|
| `{name}` | Domain name from domain.yaml |
| `{path}` | Absolute domain root path |
| `{cmd}` | Claude launch string from terminal layer |
| `{workspace_file}` | Path to `*.code-workspace` at domain root |
| `{access_file}` | Temp file with serialised `access` block from domain.yaml (only needed for container viewports — write the YAML block to a temp file if the placeholder is present in the command) |

## Step 6: Emulator Wrapping

If the matched template has `emulator: true`, wrap the command in the configured terminal emulator.

Read the emulator from `~/.claude/domain-toolkit/config.yaml` under `terminal.emulator`. Default: `alacritty`.

Apply the wrapping pattern:

| Emulator | Pattern |
|----------|---------|
| `alacritty` | `alacritty -e bash -c '<command>'` |
| `kitty` | `kitty bash -c '<command>'` |
| `wezterm` | `wezterm start -- bash -c '<command>'` |
| `gnome-terminal` | `gnome-terminal -- bash -c '<command>'` |

## Step 7: Execute

Run the final command via Bash. Use `run_in_background` for commands that spawn separate windows (IDE viewports, emulator-wrapped commands) so the skill doesn't block.

## Step 8: Report

Summarize:
- Domain: name and path
- Viewport: profile name
- Template condition matched
- Command executed (or blocked, with reason and suggested fix)
