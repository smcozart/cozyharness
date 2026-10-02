# Intent: cmu tells the operator what needs them from paths and current state, not labels

**Issue:** #31 · **Status:** approved · **Type:** bug

## Problem

`cmu` (v1.4.1) decides "Needs you" from labels only, including a
`flagged-risk` label no repo here defines. On this repo it reports "nothing
waits on you" while six open issues carry no triage label, PR #32 touches
flagged paths, and six merges plus three direct pushes on `claude-harness`
touched flagged paths with no recorded human checkoff.
Its anchor names no branch, so two runs disagreed (2026-09-13 on `main`,
2026-09-15 on `claude-harness`), and it stops at the first source rather
than the newest.

## Desired outcome

"Needs you" is derived from changed paths and the repo's written merge
policy: **merge held** for open PRs on held paths, **review owed** for merges and
direct pushes on review paths with no human checkoff since the last
board-only `STATUS.md` commit, untriaged issues counted. Today's single
"flagged risk" set reads as both held and review. The anchor is the newer of the handoff and board
commits.

## Scope

- `plugin/skills/cmu/SKILL.md` and its byte-identical `.claude` copy.
- `plugin.json` patch bump 1.4.1 → 1.4.2.

## Non-goals

- The merge policy itself (#39) and the `dispatch` hold (#42).
- Main-side adoption of `cmu` (#35).

## Acceptance criteria

- A headless read-only `cmu` run on this repo lists the untriaged issues, the
  open PR on held paths, and the merges with review owed, and names its
  anchor source as the newer of `handoffs/` and `STATUS.md`.
- `tests/validate.sh origin/main..HEAD` exits 0; `--witness` 0 unexpected;
  the two skill copies are byte-identical.

## System-intent alignment

Serves "humans stay above the loop": the operator sees every gate that waits
on them, read from the tracker and git, never from memory or labels alone.
