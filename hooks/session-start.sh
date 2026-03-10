#!/bin/bash
# Firehose SessionStart hook
# Auto-reads domain context files when starting a session in any domain.
# Install: add to ~/.claude/settings.json hooks.SessionStart (see hooks/README.md)

AGENT_MD=".context/agent.md"

if [ ! -f "$AGENT_MD" ]; then
  exit 0
fi

echo "=== Domain Agent Config ==="
cat "$AGENT_MD"
echo ""

# Follow the context map: PROFILE → MEMORY → DECISIONS → STATE
for file in .context/PROFILE.md .context/MEMORY.md .context/DECISIONS.md .context/STATE.md; do
  if [ -f "$file" ]; then
    echo "=== $(basename "$file") ==="
    cat "$file"
    echo ""
  fi
done

exit 0
