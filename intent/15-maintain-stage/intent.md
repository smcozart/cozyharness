# Intent: Maintain closes the loop — intake point, eval-on-incident, and consumer obligations as contract

**Issue:** #15 · **Status:** approved · **Type:** system-change

## Problem

Maintain is the only stage of the Harness with no codified contract. The
canonical workflow doc has no `## Maintain` section; the synced SKILL carries
only a thin "the intake point" paragraph and README a single pipeline line —
the same thinness Deploy (#12) just cured for Stage 5, now at the last stage
and the one every future adopter inherits as the loop's weakest link.
Nothing in the repo says how retro findings, incident learnings, and session
transcripts re-enter the pipeline through Plan, what happens to findings with
no textual footprint, or where drift detection and rollback sit for consumers
of the process. The playbook's Maintain play names the target — production
incidents become permanent evals, findings re-enter as intent.md through
Plan — but none of it is contract here.

## Desired outcome

Stage 6 (Maintain) is codified with the same rigor as #2/#3/#4/#9/#12: a
`## Maintain` section in `docs/engineering-workflow.md` (synced per the sync
rule at three compressions — canonical, SKILL, README — in one sha) defining
the intake point, the eval-on-incident rule, and drift/rollback as consumer
obligations. The suite's `stage-parity` check moves from 5 to 6 stages in
the same sha, with its witness rows re-recorded. CONTEXT.md gains the two
load-bearing terms the section depends on. Maintain's own tickets close under
the gate Deploy defined.

## Scope

- **Intake point as contract** — retro findings, incident-class learnings,
  and session transcripts get structured into issues and work-item intents
  and re-enter through Plan; feedback deposits into git (issues, ADRs,
  workflow doc, CONTEXT.md), never dies in chat. The loop gets shorter each
  revolution.
- **Eval-on-incident rule** — every fixed incident class becomes eval
  material in the ledger (#8), staying the Test §5 boundary until #1
  unfreezes the harness that could run those pairs. The ledger is a
  document; the only permitted writes are text — no runner, scanner, or
  automation lands here (that is #1/#8 scope).
- **Drift detection and rollback as consumer obligations** — contract text
  only; this repo has no production runtime, same shape as preview proof.
- **stage-parity update** — the check's stage set goes 5 → 6
  (Plan|Design|Build|Test|Deploy|Maintain) across the synced trio, witness
  rows re-recorded (baseline ok + historic sha reading 3/6/6 + 3 removal +
  3 rename mutations, one per leg), in the same sha as the `## Maintain`
  heading (sync execution rule; Test §4).
- **CONTEXT.md vocabulary** — two pinned terms added in the same commit as
  the section: **intake point** and **eval ledger** (definitions pinned in
  the spec; no worker-invented glossary).
- **Full-prose parity at three compressions** — the thin
  `## Maintain — the intake point` paragraph and the README `Maintain ─►`
  line are rewritten to the compressed contract in the same sha as the
  canonical section; heading-only parity is explicitly rejected.

## Non-goals

- Hooks / CI wiring / autonomous triggers / monitoring bands / rollback
  tooling — issue #1, frozen. Contracts are written extend-friendly.
- Eval harness execution — #8; the ledger stands as-is.
- The playbook's hosted products (scheduled scanning, channel on-call,
  Claude Tag) — consumer framing only.
- Reopening #2/#3/#4/#9/#12 contracts, including Deploy's merge gate.
- Sync-rule scope expansion — no new files join the synced trio.

## Acceptance criteria

- `docs/engineering-workflow.md` has a `## Maintain` section defining the
  intake point, the eval-on-incident rule, and consumer obligations for
  drift/rollback; the same commit touches
  `plugin/skills/engineering-workflow/SKILL.md` and `README.md` with
  full-prose compressed parity (sync-rule passes on that commit, per-commit).
- `stage-parity` expects 6 stages; `tests/validate.sh` exits 0 on the
  landing sha (bare at HEAD~1..HEAD, with the ticket's range, and
  `tests/validate.sh --witness` — all three pasted), and every stage-parity
  witness row still behaves: bad sha → FAIL, mutations → FAIL (one per
  leg), baseline ok → ok. Note: the suite verifies the file-triple was
  touched, not prose parity — compressed-parity wording is verified by the
  reviewer's own eye against the spec-pinned canonical text (the
  sync-content-drift gap is recorded in #8 and stays open).
- CONTEXT.md defines **intake point** and **eval ledger** exactly as the
  spec pins them.
- Each child ticket closes with pasted acceptance-criteria output AND a
  pasted `tests/validate.sh [<range>]` run under the merge gate (review
  resolution, adversary verdict, human checkoff for flagged risk,
  branch-protection paste or n/a); #15 closes only when every child is
  closed (ADR 0002).

## System-intent alignment

Purpose 3 (proof replaces claim) and the human-governed loop: the intake
point keeps humans instigating even when the signal arrives from the field —
findings become intents humans approve, never autonomous fixes. No amendment
to SYSTEM-INTENT.md needed.