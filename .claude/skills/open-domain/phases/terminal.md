# open-domain: Terminal Mode

You are launching a domain in the default terminal viewport — a bare Claude Code session in the current shell.

## Step 1: Terminal Layer

Read `refs/terminal-layer.md` and run all three steps: resolve domain, prechecks, build launch string.

## Step 2: Warn

Terminal mode launches an interactive `claude` process that takes over the current terminal. Warn the user:

> This will start a new Claude session in this terminal for **{name}** at `{path}`. Continue?

Wait for confirmation before proceeding.

## Step 3: Launch

Run via Bash:

```
cd {path} && {cmd}
```

## Step 4: Report

If blocked by a precheck, summarize:
- Domain: name and path
- Viewport: terminal
- Status: blocked (with reason and suggested fix)
