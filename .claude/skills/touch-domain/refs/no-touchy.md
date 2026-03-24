# --no-touchy Modifier

`--no-touchy` composes with any mode. When active:

- **No writes** -- don't create files, don't scaffold, don't modify anything
- **No prompts** -- don't ask about git operations
- **Full reporting** -- report everything that *would* happen

## Mode-specific behavior

- `--no-touchy` alone (default mode): report what structural validation would find/fix
- `--full --no-touchy`: report what full touch would do, including what PROFILE.md regen would produce
- `--new --no-touchy` on a nonexistent path: report what bootstrapping would create
- `--all --no-touchy`: dry-run sweep -- report what each domain's full touch would find, but write nothing
