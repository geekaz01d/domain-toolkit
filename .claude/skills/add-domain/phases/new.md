# add-domain: Scaffold New Domain (`--new`)

You are running `add-domain --new <path>` — scaffold a new domain and register it.

This is a convenience that composes two commands:

## Steps

1. Invoke `touch-domain --new <path>` to scaffold the domain (interactive onboarding, domain.yaml creation, git setup, etc.)
2. After touch-domain completes, run the single-domain registration flow to add it to the registry. Read `refs/registry-format.md` for the registry structure and `refs/path-normalization.md` for path rules.
3. Report: "Scaffolded and registered `<name>` at `<path>`."

**Important:** Do not duplicate touch-domain's logic. Delegate to it. The onboarding conversation, scaffolding, and git setup all belong to touch-domain.
