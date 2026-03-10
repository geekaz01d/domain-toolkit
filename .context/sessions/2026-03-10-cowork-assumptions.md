# Session: Runtime Verification & Build Readiness
**Date:** 2026-03-10
**Environment:** Cowork (Claude desktop app)
**Continuation of:** 2026-03-10 spec crystallization session (context compacted)

## What happened

This session picked up after the spec crystallization work was done and committed. The focus shifted from "what are we building" to "can we actually build it and how do we start."

### Runtime assumption verification
Built `verify-assumptions.sh` — a re-runnable smoke test for every runtime dependency the domain kit architecture assumes. Iterative process: the script went through several rounds of debugging because invoking `claude` as a subprocess is unreliable (hangs on auth, spawns interactive sessions, ignores SIGINT). Final approach uses `strings` on the compiled ELF binary and `grep -qF --` for flag detection. No live `claude` invocations except `claude --version`.

**All 14 checks pass:**
- Claude Code CLI 2.1.72 with --append-system-prompt-file, --system-prompt-file, --session-id, -p/--print
- Cursor CLI with --new-window
- Workspace folderOpen tasks (manually confirmed)
- SSH to fluffy, bare repo infrastructure
- Git, firehose under version control

### Environment clarifications
- Primary editor is **Cursor**, not VS Code. `cursor` is in PATH, `code` is not. All specs and scripts updated.
- LiteLLM gateway to OpenRouter available for multi-model access via Cursor.
- Claude Code binary is a compiled ELF at `~/.local/share/claude/versions/`, not an npm package. This matters for introspection (strings, not grep JS).

### Cursor agent context
Created `.cursor/rules/firehose.mdc` so Cursor agents get the same project grounding that CLAUDE.md provides for Claude Code. Points at the spec docs, command taxonomy, and domain convention.

### Build environment decision
Discussed where to build: Cowork is good for spec work and design sessions. Implementation (skill updates, hook wiring, end-to-end testing) should happen in Cursor with Claude Code. This session is the handoff point.

## Decisions made

- **Cowork for design, Cursor for implementation.** Cowork sessions produce specs and checkpoints. Cursor sessions produce code and skills.
- **`cursor` not `code`** throughout all scripts and specs.
- **No live `claude` invocations in scripts.** Use `strings` on the binary for introspection. Claude Code is too unreliable as a subprocess.
- **Session export convention** for Cowork: copy the JSONL transcript to `.context/sessions/` alongside a structured checkpoint `.md`. Convention for cross-environment sessions not yet formalized.

## Open questions

- Convention for Cowork session artifacts vs Claude Code session artifacts — same directory, different naming?
- `firehose.local.md` vs `~/.firehose/config.md` layering — when does the global config get built?
- Should `verify-assumptions.sh` become a skill or stay a standalone script?

## What's next

1. Open firehose in Cursor
2. Update `touch-domain` skill to match the spec (modal modes, git precheck)
3. Implement `open-kit` skill
4. Wire up SessionStart hook
5. End-to-end test with a real domain
