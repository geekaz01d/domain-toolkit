#!/usr/bin/env bash
# verify-assumptions.sh — smoke tests for domain kit runtime assumptions
# Run from the firehose repo root. Reports PASS/FAIL/SKIP for each check.
#
# DESIGN NOTE: We never invoke `claude` interactively. Claude Code hangs on
# auth, spawns interactive sessions, or ignores SIGINT when used as a
# subprocess. Instead we use `strings` on the compiled binary to confirm
# flag support.

set -euo pipefail

PASS=0
FAIL=0
SKIP=0
WARN=0

report() {
  local status="$1" msg="$2"
  case "$status" in
    PASS) echo -e "  ✓ PASS: $msg"; PASS=$((PASS+1)) ;;
    FAIL) echo -e "  ✗ FAIL: $msg"; FAIL=$((FAIL+1)) ;;
    SKIP) echo -e "  - SKIP: $msg"; SKIP=$((SKIP+1)) ;;
    WARN) echo -e "  ! WARN: $msg"; WARN=$((WARN+1)) ;;
  esac
}

echo "=== Domain Kit Assumption Verification ==="
echo ""

# ---------------------------------------------------------------------------
echo "1. Claude Code CLI"
echo ""

claude_bin=""
claude_real=""
if command -v claude &>/dev/null; then
  claude_bin=$(command -v claude)
  claude_real=$(readlink -f "$claude_bin" 2>/dev/null || echo "$claude_bin")
  ver=$(timeout 5 claude --version 2>&1 || echo "unknown")
  report PASS "claude CLI found: $ver"
  report PASS "binary: $claude_real"
else
  report FAIL "claude CLI not found in PATH"
fi

# ---------------------------------------------------------------------------
echo ""
echo "2-5. Claude Code CLI flags"
echo ""

# Use `strings` on the compiled binary to check for flag support
# without invoking claude interactively.
# Dump strings once, search the dump file (avoids pipe issues with large binaries)
flag_dump="/tmp/firehose-claude-strings.txt"
if [ -n "$claude_real" ] && [ -f "$claude_real" ]; then
  strings "$claude_real" > "$flag_dump" 2>/dev/null
fi

check_flag_in_binary() {
  local flag="$1" desc="$2"
  if [ ! -f "$flag_dump" ]; then
    report SKIP "$desc — could not extract binary strings"
    return
  fi
  # Use -- to stop option parsing, -F for literal match
  if grep -qF -- "$flag" "$flag_dump"; then
    report PASS "$desc"
  else
    report WARN "$desc — not found in binary strings"
  fi
}

check_flag_in_binary "append-system-prompt-file" "--append-system-prompt-file (agent.md injection)"
check_flag_in_binary "system-prompt-file"        "--system-prompt-file (distiller prompt)"
check_flag_in_binary "session-id"                "--session-id (session tracking)"
check_flag_in_binary "--print"                   "-p / --print (headless mode)"

rm -f "$flag_dump"

# ---------------------------------------------------------------------------
echo ""
echo "6. Editor CLI (Cursor / VS Code)"
echo ""

# Prefer cursor, fall back to code
editor_cmd=""
if command -v cursor &>/dev/null; then
  editor_cmd="cursor"
  editor_ver=$(cursor --version 2>&1 | head -1 || echo "unknown")
  report PASS "cursor CLI found: $editor_ver"
elif command -v code &>/dev/null; then
  editor_cmd="code"
  editor_ver=$(code --version 2>&1 | head -1 || echo "unknown")
  report PASS "code CLI found: $editor_ver"
else
  report FAIL "neither cursor nor code CLI found in PATH"
fi

# ---------------------------------------------------------------------------
echo ""
echo "7. Editor CLI flags"
echo ""

if [ -n "$editor_cmd" ]; then
  editor_help=$($editor_cmd --help 2>&1 || true)
  if echo "$editor_help" | grep -q "\-\-new-window"; then
    report PASS "$editor_cmd --new-window flag available"
  else
    report WARN "$editor_cmd --new-window not confirmed in help output"
  fi
else
  report SKIP "no editor CLI available"
fi

# ---------------------------------------------------------------------------
echo ""
echo "8. Workspace folderOpen tasks (manual)"
echo ""

test_ws="/tmp/firehose-verify-test.code-workspace"
cat > "$test_ws" << 'WORKSPACE'
{
  "folders": [
    { "path": "/tmp" }
  ],
  "tasks": {
    "version": "2.0.0",
    "tasks": [
      {
        "label": "Verify folderOpen",
        "type": "shell",
        "command": "echo FIREHOSE_FOLDEROPEN_WORKS > /tmp/firehose-folderopen-result.txt",
        "presentation": { "reveal": "silent" },
        "runOptions": { "runOn": "folderOpen" }
      }
    ]
  }
}
WORKSPACE

if [ -f /tmp/firehose-folderopen-result.txt ] && grep -q "FIREHOSE_FOLDEROPEN_WORKS" /tmp/firehose-folderopen-result.txt 2>/dev/null; then
  report PASS "folderOpen tasks work (confirmed by previous manual test)"
else
  open_cmd="${editor_cmd:-code}"
  report SKIP "folderOpen tasks require manual test"
  echo "         Run:   $open_cmd --new-window $test_ws"
  echo "         Check: cat /tmp/firehose-folderopen-result.txt"
  echo "         Then re-run this script to confirm."
fi

# ---------------------------------------------------------------------------
echo ""
echo "9. SSH to primary git server"
echo ""

git_host="root@fluffy.geekazoid.net"
git_path="/mnt/user/git"

if ssh -o ConnectTimeout=5 -o BatchMode=yes "$git_host" "echo reachable" 2>/dev/null | grep -q reachable; then
  report PASS "SSH to $git_host works"

  if ssh -o ConnectTimeout=5 "$git_host" "test -d $git_path && echo exists" 2>/dev/null | grep -q exists; then
    report PASS "$git_path exists on server"
    if ssh -o ConnectTimeout=5 "$git_host" "test -d $git_path/firehose.git && echo exists" 2>/dev/null | grep -q exists; then
      report PASS "firehose.git bare repo exists on server"
    else
      report WARN "firehose.git bare repo not found on server"
    fi
  else
    report FAIL "$git_path not found on server"
  fi
else
  report FAIL "SSH to $git_host failed"
fi

# ---------------------------------------------------------------------------
echo ""
echo "10. Git"
echo ""

if command -v git &>/dev/null; then
  git_ver=$(git --version 2>&1)
  report PASS "$git_ver"
else
  report FAIL "git not found"
fi

if git -C "$(dirname "$0")" rev-parse --git-dir &>/dev/null; then
  report PASS "firehose repo is under git"
else
  report WARN "firehose repo is NOT a git repo yet"
fi

# ---------------------------------------------------------------------------
echo ""
echo "11. claudeProcessWrapper (editor setting)"
echo ""

# Check both Cursor and VS Code settings paths
found_wrapper=false
for settings_path in \
  "$HOME/.config/Cursor/User/settings.json" \
  "$HOME/.config/Code/User/settings.json"; do
  if [ -f "$settings_path" ]; then
    if grep -q "claudeProcessWrapper\|claude.processWrapper" "$settings_path" 2>/dev/null; then
      report PASS "claudeProcessWrapper configured in $settings_path"
      found_wrapper=true
      break
    fi
  fi
done
if [ "$found_wrapper" = false ]; then
  report SKIP "claudeProcessWrapper not configured (optional — for session log capture)"
fi

# ---------------------------------------------------------------------------
echo ""
echo "12. Claude Code hooks"
echo ""

claude_settings="$HOME/.claude/settings.json"
if [ -f "$claude_settings" ] && grep -q "hooks" "$claude_settings" 2>/dev/null; then
  report PASS "hooks configured in $claude_settings"
else
  report SKIP "No hooks configured yet (needed for SessionStart auto-context)"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Summary ==="
echo "  PASS: $PASS  |  FAIL: $FAIL  |  WARN: $WARN  |  SKIP: $SKIP"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "Some checks failed. Review above for details."
  exit 1
else
  echo "No hard failures. SKIP/WARN items need manual verification or future setup."
  exit 0
fi
