#!/bin/bash
# Domain-toolkit SessionStart hook
# Two jobs:
#   1. If managed domain (.claude/domain-toolkit/domain.yaml exists): inject context files
#   2. Always: record session mapping for transcript retrieval
#
# Load order (per file-convention.md):
#   1. Global governance (~/AGENTS.md, ~/.claude/CLAUDE.md) — handled by CC natively
#   2. Domain governance (CLAUDE.md, AGENTS.md) — handled by CC natively
#   3. Persona (closest persona.md to launch context)
#   4. Context files (PROFILE → MEMORY → DECISIONS → STATE)
#
# This hook handles steps 3-4. Steps 1-2 are CC's native behaviour.
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
  echo "{\"session_id\":\"$SESSION_ID\",\"transcript_path\":\"$TRANSCRIPT_PATH\",\"cwd\":\"$CWD\",\"source\":\"$SOURCE\",\"started\":\"$TIMESTAMP\"}" \
    >> ".context/sessions/session-index.jsonl"
fi

# --- Domain context injection (only for managed domains) ---
DOMAIN_YAML=".claude/domain-toolkit/domain.yaml"

if [ ! -f "$DOMAIN_YAML" ]; then
  exit 0
fi

# Inject persona (closest persona.md to launch context)
# Check domain root first, then fall back to skill-specific or global
if [ -f "persona.md" ]; then
  echo "=== Persona ==="
  cat "persona.md"
  echo ""
fi

# Follow the context map: PROFILE → MEMORY → DECISIONS → STATE
for file in .context/PROFILE.md .context/MEMORY.md .context/DECISIONS.md .context/STATE.md; do
  if [ -f "$file" ]; then
    echo "=== $(basename "$file") ==="
    cat "$file"
    echo ""
  fi
done

exit 0
