# Handoffs

Session-to-session handoff documents, moved into the repo so they are
versioned and travel with clones. Each is a **context-under-the-floor of a
session** — the durable truth stays in the tracker, commits, specs, ADRs and
STANDARD.md; these capture the "you should pick up here" context that lives
in session chat.

| Doc | What it covers |
|---|---|
| `pickup-handoff.md` | **Current** — the live pickup point: re-enter the Harness, read `../STATUS.md`, open frontier, queued next. |
| `deploy-to-maintain-handoff.md` | Handover from the Deploy stage → Maintain stage. |
| `test-to-deploy-stage-handoff.md` | Test → Deploy handover. |
| `build-stage-handoff.md` | Build-stage handover. |
| `design-stage-handoff.md` | Design-stage handover. |

## Rules

- A session writes its own handoff to `handoffs/pickup-handoff.md` (or a
  new `handoffs/<nick>.md` when it's a relation), keeping the latest pickup
  file current.
- Reference artifacts by path; do not duplicate spec/intent/ADR/issue text.
- Redact secrets/PII (none live in this repo's committed docs).
- The repo's board snapshot is `STATUS.md` (root); STATUS + this folder are
  the "where we are" starting point for a fresh session.