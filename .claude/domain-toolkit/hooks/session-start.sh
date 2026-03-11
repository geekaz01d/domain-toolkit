#!/bin/bash
# Firehose SessionStart hook
# Two jobs:
#   1. If domain (.claude/agent.md exists): inject context files as opening context
#   2. Always: record session mapping for transcript retrieval
#
# Install: add to ~/.claude/settings.json hooks.SessionStart (see hooks/README.md)

# --- Session index (always, regardless of domain) ---
# Read hook input from stdin (JSON with session_id, cwd, transcript_path, source)
HOOK_INPUT=$(cat)

SESSION_ID=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)
CWD=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('transcript_path',''))" 2>/dev/null)
SOURCE=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('source',''))" 2>/dev/null)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ -n "$SESSION_ID" ] && [ -d ".context/sessions" ]; then
  # Domain-local session index — each domain owns its session records
  echo "{\"session_id\":\"$SESSION_ID\",\"transcript_path\":\"$TRANSCRIPT_PATH\",\"source\":\"$SOURCE\",\"started\":\"$TIMESTAMP\"}" \
    >> ".context/sessions/session-index.jsonl"
fi

# --- Domain context injection (only for domains) ---
AGENT_MD=".claude/agent.md"

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
