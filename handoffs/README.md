# Handoffs

Session-to-session handoff documents, moved into the repo so they are
versioned and travel with clones. Each is a **context-under-the-floor of a
session** — the durable truth stays in the tracker, commits, specs, ADRs and
STANDARD.md; these capture the "you should pick up here" context that lives
in session chat.

> **The live board is `../STATUS.md`** — the single file a fresh session reads
> first for "where are we?". This folder is **archival**: point-in-time session
> context, not a second live board. Nothing here is edited per session as the
> source of state.

| Doc | What it covers |
|---|---|
| `pickup-handoff.md` | Latest session pickup (archived) — re-enter the Harness; for current state read `../STATUS.md`. |
| `deploy-to-maintain-handoff.md` | Handover from the Deploy stage → Maintain stage. |
| `test-to-deploy-stage-handoff.md` | Test → Deploy handover. |
| `build-stage-handoff.md` | Build-stage handover. |
| `design-stage-handoff.md` | Design-stage handover. |

## Rules

- A session archives its handoff here as a new `handoffs/<date-or-nick>.md`;
  it does **not** overwrite a "current" file to mirror live state. The live
  board is `../STATUS.md` — update that, not this folder.
- Reference artifacts by path; do not duplicate spec/intent/ADR/issue text.
- Redact secrets/PII (none live in this repo's committed docs).
- **Mind the sync:** `../STATUS.md` (root) is the single live board; keep it
  current on each milestone close or intake decision. This folder is archival
  session context, never a second live mirror of the board.