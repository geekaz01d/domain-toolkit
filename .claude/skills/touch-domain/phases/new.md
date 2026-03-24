# touch-domain: New Mode (`--new`)

You are running `touch-domain --new`. This bootstraps a new domain at the specified path. The path may or may not exist yet.

Read `domain-yaml-schema.md` for the domain.yaml schema and `file-convention.md` for the file hierarchy.

## Step 1: Pre-flight

If the path already has `.context/`, warn: "This already looks like a domain. Did you mean `touch-domain <path>` (default) or `touch-domain --full <path>`?"

If `--no-touchy` is set, read `refs/no-touchy.md` -- report what bootstrapping would create and stop.

## Step 2: Create Directory

Create the domain directory if it doesn't exist.

## Step 3: Interactive Onboarding

Begin an interactive conversation with the user about:
- What is this domain? What does it contain?
- What's its scope? Narrow or broad?
- Agent persona and model tier preference
- Initial concerns or priorities

## Step 4: Scaffold Domain

From the onboarding conversation, create:
- `.claude/domain-toolkit/domain.yaml` (manifest, detection signal) -- tracked in git
- `persona.md` (agent identity, model tier, context map) -- tracked in git
- `README.md` at domain root (from the user's description)
- `.context/` directory with scaffolding (gitignored):
  - Initial `STATE.md`, `MEMORY.md` (minimal), `DECISIONS.md` (empty structure)
  - `sessions/` directory

## Step 5: Capture Session

Capture the onboarding conversation as the first session artifact in `.context/sessions/`.

## Step 6: Git Initialization

If the domain is not already a git repo, offer to initialize git:
- Prompt: "Initialize git for this domain?" (unless `-y` auto-confirms)
- If yes: `git init`, prompt to create bare repo on the server per `default_remote_pattern` in the meta-domain's `domain.yaml` (read from `~/.claude/domain-toolkit/domain.yaml`), configure origin remote, initial commit with scaffolding
- If no: skip. "Domain created without git. You can initialize git later with `git init`."

## Step 7: Profile and Workspace Generation

Run the full-mode content synthesis and generation:
1. Read the canonical context files just created
2. Regenerate `.context/PROFILE.md` with a summary of the new domain
3. Generate `domain.code-workspace` at the domain root (two folders: domain root + `.context/`, `folderOpen` task, extension recommendation)

## Step 8: Report

Summarize what was created:
- Domain root path
- Files scaffolded
- Git state (initialized or not)
- Suggest: `open-domain <domain> --cursor` to start working
