# Board State

**Updated:** 2026-09-13 (Hooks core closed; V1 milestone + Claude parity.) · maintain with each milestone.

This is the one file a fresh session reads first to answer "where are we?". It is a **pointer to the tracker**, never a duplicate — the tracker stays the system of record; STATUS.md only mirrors the current snapshot and the operator queue.

## Where the board is

**Closed with proof:** the six-stage loop — Plan #2 · Design #3 · Build #4 ·
Test #9 · Deploy #12 · Maintain #15 — plus **Claude Code host parity #19/#20**
and the **hooks-core landing #21/#22** (a7f7523). Milestone tag:
`v1-harness-complete`.

## Open (live frontier)

- #1 Hooks as enforcement layer (parent) — open for the **pi event-advisor** intent + any later per-host work
- #8 Eval ledger — text-only ledger
- #18 Two carried LOW findings (owner: operator; finding 1 self-resolves on the next trio touch)
- #23 Hooks envelope limit — pre-push checks the pushed refs, not the HEAD (owner: operator, at a spec amendment)

## Queued next

- **Claude-host pipeline pilot** — one real ticket through the full pipeline, Claude Code as orchestrator + worker (the agreed next intake).

## How to stay on track (re-entry)

```
gh issue list --state open            # start at the live frontier
cat CONTEXT.md SYSTEM-INTENT.md      # vocabulary + alignment
cat docs/training/onboarding-runbook.md  # clone→bootstrap→first-intake
tests/validate.sh                     # the gate is the floor
```

When you read this file, fetch the open issues — STATUS.md is a snapshot, the
tracker is the truth. All gates are human (the paste checkoff, and the
merge-gate pasted proof); never let a hook replace that with an auto-yes.

## Maintain this file

Update it on each milestone close or intake decision (add/remove open rows,
roll the Queued slot). The operator owns it; a worker touches it only as a
destruct item on a milestone.