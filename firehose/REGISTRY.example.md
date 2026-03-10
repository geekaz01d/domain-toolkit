# Firehose Domain Registry (Example)

This file shows an example layout for a firehose domain registry, used by the `/firehose` skill to coordinate a serial sweep.

You can copy or adapt this into `firehose/REGISTRY.md` in a real project.

## Status values

- `pending` – domain has not been swept in the current run.
- `active` – currently being worked on.
- `complete` – sweep finished for this run.
- `deferred` – intentionally skipped for now.

## Example registry

```markdown
# Firehose Domain Registry

| Domain      | Path                          | Status   | Last touched   | Notes                         |
|------------|-------------------------------|----------|----------------|-------------------------------|
| firehose   | ./                             | pending  | 2026-03-09     | Specs and skills              |
| app-core   | ../some-app/app-core          | pending  | 2026-03-08     | Main application core         |
| billing    | ../some-app/billing           | deferred | 2026-03-01     | Waiting on upstream changes   |
| infra      | ../infra                       | complete | 2026-02-28     | Baseline sweep already done   |
```

In practice:

1. Create `firehose/REGISTRY.md` based on this template.
2. Populate it with real domain names and paths.
3. Use the `/firehose` skill in Claude Code to select the next `pending` domain, mark it `active`, and guide your sweep.

