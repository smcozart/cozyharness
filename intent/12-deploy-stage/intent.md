# Intent: Deploy is its own stage — review loop, merge gate, and autonomy boundaries as contract

**Issue:** #12 · **Status:** approved · **Type:** system-change

## Problem

Test (#9) formalized the Test gate. Deploy, Stage 5 of the playbook loop, is
still empty prose ("branch protection is the gate") — the thinnest stage in
the Harness and the one every future adopter inherits its thinness from.
Nothing in the repo says what a PR owes before merge, who reviews agent-
written diffs and against what policy, how branch protection is verified, or
which changes an agent may merge without a human. The pieces exist
uncontracted: the `code-review` skill and the mandatory adversary pass are
session habits, not Deploy-stage obligations.

## Desired outcome

Stage 5 (Deploy) is codified with the same rigor as #2/#3/#4/#9: a `## Deploy`
section in `docs/engineering-workflow.md` (synced per the sync rule) that
defines the PR review loop, the merge gate, branch-protection verification,
and autonomy boundaries. The review policy lives in a root `REVIEW.md`,
subordinate to the Deploy section — the section names the gate; REVIEW.md is
the checklist it references. The suite's `stage-parity` check moves from 4 to
5 stages in the same sha as the doc change, with its witness re-verified.
Deploy's own tickets close under the gate they define: pasted
`tests/validate.sh` run, review findings resolved, adversary verdict.

## Scope

- **PR review loop as a contract** — review policy artifact at
  `REVIEW.md` (passes, severity: Important vs Nit, skip-list), subordinate
  to the Deploy section; reviewers give and receive reviews; the existing
  `code-review` skill + adversary pass become Deploy-stage obligations.
- **Merge gate definition** — what a PR owes before merge: review findings
  resolved, `tests/validate.sh [<range>]` run pasted, adversary verdict,
  human checkoff for flagged risk, and for UI tickets a preview proof
  (screenshot / recording / standing link) pasted at close — written as a
  consumer obligation, contract text only.
- **Branch-protection verification** — a documented manual proof
  (`gh api .../branches/main/protection` pasted at close), extend-friendly
  when #1 unfreezes. `tests/validate.sh` stays offline (Test §5); no
  branch-protection check joins the suite.
- **Autonomy boundaries** — which changes need a human gate vs which an
  agent may self-merge, docs-first.
- **stage-parity update** — the check's stage set goes 4 → 5
  (Plan|Design|Build|Test|Deploy) across the synced trio, witness row
  updated or re-recorded, in the same sha as the `## Deploy` heading
  (sync execution rule; Test §4).

## Non-goals

- Hooks / CI wiring / server-side enforcement — issue #1, frozen.
- Docker / sandbox / containers — the out-of-scope set from intake; belongs
  to #1 or the first consumer codebase with a real runtime.
- Visualization runtime for this repo — no UI surface here; preview proof is
  a consumer obligation written into the contract.
- A branch-protection check in `tests/validate.sh` — the suite is offline by
  contract (Test §5); manual pasted evidence is the answer.
- Sync-rule scope expansion — `REVIEW.md` is referenced by the Deploy
  section, not added to the synced trio.
- Reopening #2/#3/#4/#9 contracts.

## Acceptance criteria

- `docs/engineering-workflow.md` has a `## Deploy` section defining the
  review loop, the merge gate, branch-protection verification, and autonomy
  boundaries; the same commit touches
  `plugin/skills/engineering-workflow/SKILL.md` and `README.md` (sync-rule
  passes on that commit).
- `REVIEW.md` exists at repo root with the passes, the Important-vs-Nit
  severity rule, and the skip-list; the Deploy section references it by
  path.
- `stage-parity` expects 5 stages; `tests/validate.sh` exits 0 on the
  landing sha and `tests/validate.sh --witness` exits 0 (every witness row
  still behaves: bad sha / mutation → FAIL, good sha → ok), both runs
  pasted at close.
- The branch-protection verification is written as a manual `gh api` proof
  procedure; no online check is added to the suite.
- Autonomy boundaries are written down: human-gated vs self-mergeable
  change classes, docs-first.
- Each child ticket closes with pasted acceptance-criteria output AND a
  pasted `tests/validate.sh [<range>]` run; #12 closes only when every
  child is closed (ADR 0002).

## System-intent alignment

Purpose 3 (proof replaces claim) — the merge gate is pasted evidence, not a
reviewer's say-so; the human-governed loop — autonomy boundaries make
explicit where the human gate sits, so governance is enforced as the agent
acts. No amendment to SYSTEM-INTENT.md needed.
