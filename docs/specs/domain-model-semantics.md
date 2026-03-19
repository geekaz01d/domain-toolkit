# Domain Model Semantics

**Status:** Draft — captured from working session 2026-03-18
**Context:** Clarifies the conceptual model underlying domain-toolkit. Intended as a durable reference so the model doesn't need to be re-derived in future sessions.

---

## Domain Types

### Subject Domains

A subject domain models a **concern in the world** — something the operator acts upon. It is outward-facing. Examples: a finance system, a client engagement, an infrastructure stack, a software project.

Subject domains are where work gets done. Each has its own repository, its own domain kit (context, memory, decisions, state), and potentially its own build artifacts and services.

### Personal Domain

A personal domain models the **operator themselves**. It is reflexive — the system looking inward rather than outward. It captures the human's goals, state, availability, capacity, constraints, schedule, and resources.

There is exactly one personal domain per operating unit. For an individual, this is their own. For a household or tightly-coupled pair (low barriers, shared life), a single personal domain can serve both people.

The personal domain is distinct from all subject domains because it doesn't represent a concern to be worked on — it represents the human capacity that determines *which* concerns get attention and *when*.

### Operator Domains (General Category)

Both personal domains and (future) team domains share a common quality: they model **who is doing the work** rather than **what is being worked on**. The general term for this category is *operator domain*.

In the current implementation, only the personal domain tier exists. In an organisational setting, additional tiers would emerge:

- **Personal domain** — individual operator. Their capacity, goals, state.
- **Team / unit domain** — shared context for a group. Shared capacity, shared commitments, coordination concerns.

These tiers are not in scope today but the semantics are designed to accommodate them cleanly.

---

## Authorship vs. Operation

### The Domain Owns Its Code

A domain is the **complete unit of authorship**. Everything from conception through to a deployable artifact happens inside the domain workspace, with the domain kit providing context.

This includes:

- Application logic, data models, configuration
- Pipelines, scripts, Claude skills
- Build artifacts (Dockerfiles, compose fragments, build directories)

If you are authoring it, you are working in the domain that owns it.

### The Build Artifact Is the Handoff Point

The build directory in a domain's repository is the **last thing the domain owns**. It is a fully specified, portable artifact. What happens after that point is deployment.

### Deployment Is an Operational Concern

Deployment binds a domain's build artifact to a specific runtime environment. Today this might be a symlink into a server's appdata directory where a Docker image is built and started. Tomorrow it could be a CI push to a public VPS. The domain doesn't prescribe this — it produces the artifact; the operator decides where and how it runs.

An operator domain like `systems-geekazoid` owns the operational lifecycle:

- Container runtime and networking
- Host-level bind mounts and environment config
- Dependency infrastructure (shared services consumed but not owned by the subject domain)
- Service runbooks that reference the source domain's build artifacts

### The Lifecycle

1. **Author** — inside the domain, using the domain kit, with full context
2. **Build** — produces a deployable artifact, still inside the domain repo
3. **Bind** — the artifact is connected to a runtime environment (environment-specific, not domain-owned)
4. **Operate** — an operator domain (e.g. systems-geekazoid) runs, monitors, and documents the service

### Traceability

The operator domain's runbook should reference the source domain for each service it operates. The registry should note which subject domains produce deployable artifacts, so the operator domain knows what it is responsible for.

---

## The Overview Function

The orchestrator's overview (or sweep) function operates across two inputs:

1. **Registry scan** — read all subject domain profiles. What's blocked? What's decaying? What's urgent? What needs attention?
2. **Personal domain profile** — read the operator's current state. What capacity exists? What constraints apply right now?

The output is a **capacity-aware briefing** — not an exhaustive list of everything that needs doing, but a prioritised view filtered through the human's actual ability to respond.

The personal domain is the **first read** in any sweep, not the last. You read the operator's state first and filter the subject domains through it.

---

## Grouping, Segmentation, and Visibility

- **Grouping**: Subject domains can be grouped by directory structure (e.g. `infrastructure/systems-*`). Grouping is organisational, not hierarchical — grouped domains are still independent.
- **External/client segmentation**: Client or external domains should be properly segmented from personal domains, both for operational hygiene and access control.
- **Visibility control via branches**: Git branches handle segmentation where needed. A domain may have a public branch for open-source distribution while keeping its working branch private (e.g. domain-toolkit's `public` branch).

---

## Dependencies and Reference Material

Third-party upstream clones (e.g. `beancount`, `fava`) are **dependencies** of the domains that use them. They are not domains in their own right and do not appear in the registry. They are reference material — a library shelf that subject domains draw from.

---

## Personal Domain Internal Structure

The personal domain is not a flat profile — it has its own internal data layer with a taxonomy of domain-like objects (shared concerns, user trees, projects, subagents, external dataset references). These are fundamentally different from subject domains: they are lightweight, semantic, and managed within a shared data structure rather than as independent repos with kits.

The personal domain's internal structure is defined by the personal domain itself, not by domain-toolkit. Domain-toolkit defines only the **interface**: the overview function reads the personal domain's profile for operator capacity, state, and constraints. How the personal domain organises its internals — its data model, principals, areas, values, goals, projects — is its own concern.

**Key interface points for domain-toolkit:**

- The overview function reads the personal domain profile as its first input
- Projects within the personal domain may **graduate** into subject domains when they need collaboration with external principals, become client engagements, grow heavy enough for their own kit, or reach end-of-life for archival. Graduation uses an overlay model: the project becomes a subject domain repo while the personal domain retains metadata links and the time management view.
- The personal domain can reference external datasets (e.g. libraries, recipe databases) without containing them.

**See:** The personal domain's own documentation for its data model specifics (e.g. `cursus/control/specs/`).

---

## Terminology Summary

| Term | Meaning |
|------|---------|
| **Subject domain** | A concern in the world. Outward-facing. Where work happens. |
| **Personal domain** | A model of the operator. Reflexive. Inward-facing. Contextualises all other domains. |
| **Operator domain** | General category for domains that model who does the work (personal, team). |
| **Domain kit** | The complete set of domain-specific resources: context, memory, decisions, state, skills, sessions. |
| **Build artifact** | The handoff point between authorship (domain) and deployment (operator). |
| **Deployment binding** | Environment-specific connection between a build artifact and a runtime. Not domain-owned. |
| **Overview / sweep** | Registry scan filtered through personal domain profile. Capacity-aware prioritisation. |
| **Graduation** | A personal domain project becoming a subject domain repo. The personal domain retains metadata and time management as an overlay. |
