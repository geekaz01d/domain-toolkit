# Firehose Hooks

Claude Code hooks that automate the domain kit lifecycle.

## session-start.sh

Fires on every Claude Code session start. If the working directory contains `.claude/agent.md`, injects the domain's context files as opening context:

1. `.claude/agent.md` — agent persona, model tier, context map
2. `.context/PROFILE.md` — derived domain briefing
3. `.context/MEMORY.md` — accumulated cross-session understanding
4. `.context/DECISIONS.md` — decision log with rationale
5. `.context/STATE.md` — current status and open threads

Non-domain directories (no `.claude/agent.md`) are unaffected.

## Installation

### 1. Copy the hook script

```bash
mkdir -p ~/.claude/hooks
cp hooks/session-start.sh ~/.claude/hooks/session-start.sh
chmod +x ~/.claude/hooks/session-start.sh
```

### 2. Add to ~/.claude/settings.json

Merge this into your `settings.json` (create the file if it doesn't exist):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "\"$HOME\"/.claude/hooks/session-start.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

If you already have other hooks, add the `SessionStart` entry alongside them.
