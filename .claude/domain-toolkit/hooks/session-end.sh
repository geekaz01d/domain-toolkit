#!/bin/bash
# Domain-toolkit SessionEnd hook
# Two jobs for managed domains:
#   1. Stage the just-ended session's transcript into .context/sessions/
#   2. Harvest CC auto-memory into .context/memory/
#
# Runs async (fire-and-forget) — the session closes immediately.
# Idempotent with cron fallback — safe to run both.
#
# Install: add to ~/.claude/settings.json hooks.SessionEnd (see hooks/README.md)

set -euo pipefail

# --- Read hook input from stdin ---
HOOK_INPUT=$(cat)

SESSION_ID=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)
CWD=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('transcript_path',''))" 2>/dev/null)

# Bail if we don't have what we need
if [ -z "$SESSION_ID" ] || [ -z "$CWD" ]; then
  exit 0
fi

# Only act on managed domains with session storage
SESSIONS_DIR="$CWD/.context/sessions"
if [ ! -d "$SESSIONS_DIR" ]; then
  exit 0
fi

# --- 1. Stage transcript ---
# Run stage-transcripts for this domain only.
# The stager reads session-index.jsonl and extracts JSONL into .transcript.md files.
STAGER="$HOME/sources/domain-toolkit/.claude/domain-toolkit/bin/stage-transcripts"
if [ -x "$STAGER" ] || [ -f "$STAGER" ]; then
  python3 "$STAGER" 2>/dev/null || true
fi

# --- 2. Harvest CC auto-memory ---
# Compute the encoded project path from CWD
ENCODED_PROJECT=$(echo "$CWD" | sed 's|^/||; s|/|-|g')
CC_MEMORY_DIR="$HOME/.claude/projects/-${ENCODED_PROJECT}/memory"

if [ -d "$CC_MEMORY_DIR" ]; then
  DOMAIN_MEMORY_DIR="$CWD/.context/memory"
  mkdir -p "$DOMAIN_MEMORY_DIR"

  HARVEST_LOG="$DOMAIN_MEMORY_DIR/.harvest-log"
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Copy new or modified files (preserve originals)
  for src_file in "$CC_MEMORY_DIR"/*; do
    [ -f "$src_file" ] || continue
    filename=$(basename "$src_file")
    dest_file="$DOMAIN_MEMORY_DIR/$filename"

    # Copy if dest doesn't exist or source is newer
    if [ ! -f "$dest_file" ] || [ "$src_file" -nt "$dest_file" ]; then
      cp "$src_file" "$dest_file"
      echo "${TIMESTAMP}	${SESSION_ID}	${filename}	harvested" >> "$HARVEST_LOG"
    fi
  done
fi

exit 0
