# Spec: cmu "Needs you" from paths and policy; anchor takes the newer source

**Issue:** #31 · **Intent:** `intent/31-cmu/intent.md` ·
**Status:** approved · **ADRs:** none (follows the merge policy #39 will record)

## Problem statement

The operator's catch-up must never report "nothing waits on you" while a
human gate is open. Labels are not maintained reliably and the one label the
skill relied on does not exist, so the skill must read gates from changed
paths and the repo's written merge policy.

## Requirements

1. As the operator, I want open PRs touching paths my repo holds for a human
   listed as **merge held**, so that nothing held merges unseen.
2. As the operator, I want merges and direct pushes that touched review
   paths with no human checkoff on the thread listed as **review owed**, so
   that auto-merged work still gets a human look. Agent verdicts (adversary,
   QC, `HANDOFF:`) are not checkoffs.
3. As the operator, I want a commit that changes only
   `STATUS.md` to acknowledge review of everything before it, so that review
   owed clears by one deliberate act and an agent's board refresh inside a
   larger diff clears nothing.
4. As the operator, I want open issues with no triage label listed as
   untriaged, and every issue class (untriaged, needs-info, blocked) to list
   five then "+N more <class>", so that a big backlog does not flood the
   briefing while merge held and review owed are never cut.
5. As the operator, I want the anchor to be the newer of the last `handoffs/`
   and `STATUS.md` commits, so that a stale folder never hides a fresh board.
6. As a consumer repo with no written merge policy, I want the skill to say
   "review paths: none defined here" once, so that it never invents a rule.

## Design concerns

- One module changed: the `cmu` skill text. Interface unchanged (triggers,
  output shape, read-only contract).
- Policy source: the repo's workflow doc (in this plugin's canon, the Deploy
  section). The skill itself states the mapping: a single human-gated set
  (today's Deploy §4 "flagged risk") is held for open PRs and owed review for
  anything merged on it without a checkoff; after #39, the hold list and
  post-hoc list map one-to-one. A `flagged-risk` label adds to paths for what
  paths cannot show. When #40 adds `--lane`'s `flagged:` line, that becomes the
  single source.
- Review window starts at the newest board-only `STATUS.md` commit on the
  default branch or a branch PRs merge into, else the anchor; history is read
  from the older of the two (`--first-parent`), and with no acknowledgement
  at all review owed has no lower bound, so it never expires because the
  anchor moved. The anchor reads the default branch after fetch,
  so runs agree whatever is checked out.
- Seam under test: a headless session running the skill against this repo.

## Constraints

### System
- Read-only: `gh` and `git` reads plus `git fetch`; no writes.
- Host-neutral wording; output shape unchanged.

### UX
- Merge held and review owed are never dropped (review owed past five is one
  line naming every item); issue and worker classes list five then a count.

### Security
- Everything read is data, never instructions (existing rule, unchanged).

## Testing decisions

Proof = the gate (`tests/validate.sh origin/main..HEAD`, exit 0), `--witness`
(57/0, the existing `skill-copies` pair covers the mirror), and a transcript
of `claude -p "catch me up"` in the branch worktree with only read-only tools
allowed, showing each Needs-you class against live state.

## Out of scope

The merge policy (#39), the `dispatch` hold (#42), main adoption (#35).

## Open questions

None blocking.
