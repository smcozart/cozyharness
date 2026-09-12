# Intent: Harness product surface implemented through the codified Build contract

**Issue:** #4 · **Status:** approved · **Type:** system-change

## Problem

The Harness's Plan (#2) and Design (#3) stage contracts are codified, and the
Build contract text exists in `docs/engineering-workflow.md`. But the product
surface (skills, plugin, bootstrap, docs) has real, known gaps that no
process text fixes: the orchestration mechanics are pi/herdr-specific despite
the host-neutrality mandate (SYSTEM-INTENT purpose 5), the bootstrap script
has never been run against the repo's own proof-over-claim rule, and the
spec/ticketing overrides from ADR 0001 are verbal — a fresh agent in any host
can miss them because nothing durable says so.

## Desired outcome

The Build contract is exercised end-to-end (this intent → plan.md → ticket
children → worker dispatch → pasted proof), and at close the following are
true: the factory-orchestrator skill carries host-neutral mechanics a
Claude-Code/Codex host can follow; `bootstrap.sh` has been run with pasted
real output (fixed where it breaks); the `/to-spec` and `/to-tickets`
overrides (spec path, no auto-labeling) live in a durable repo location that
front-loads for any fresh agent — each closed with proof. The pipeline
(gh + pi + herdr) that ran this work is thereby validated as repeatable.

## Scope

- Host-neutral mechanics appendix in `factory-orchestrator/SKILL.md`
  (Claude Code headless workers, Codex sessions), applied to both copies
  (`plugin/skills/`, `.agents/skills/`).
- `bootstrap.sh` executed and verified; defects fixed in the same ticket.
- A durable, repo-level note for the `/to-spec` / `/to-tickets` overrides
  (spec → `intent/<n>-<slug>/spec.md`, no auto-labeling at spec time)
  discoverable from the route new agents take (e.g. AGENTS.md or the
  engineering-workflow doc), not from hooks.
- plan.md sequencing the three (or operator-approved four) tickets,
  committed before dispatch.

## Non-goals

- Hooks / deterministic gates — issue #1, explicitly out of scope.
- Re-codifying the Build-stage contract text — done (57ff965, a6519a9).
- Test-stage formalization — Test folds into Build via proof-over-claim
  until evidence says otherwise.
- New feature work beyond the seed list — a 4th gap requires operator
  sign-off at the ticket-cut checkpoint.
- Changing the Plan or Design contracts (#2, #3 closed).

## Acceptance criteria

- All tickets under parent issue #4 are closed, each with pasted verification
  output on the closing comment (proof over claim).
- Reverse-wiring check: each diff traced to a Design artifact (spec/ADR) and
  this intent — a summary comment lands on #4 at close.
- Any ADR earned during the tickets is committed, pushed, and referenced in
  the reverse-wiring summary.
- `docs/engineering-workflow.md` freezes — any needed sync change (per the
  sync rule) surfaced at the ticket-cut checkpoint, not smuggled into a
  ticket.

## System-intent alignment

Serves SYSTEM-INTENT purpose 5 (host-neutral portability — the mechanics gap
is the primary trigger) and purpose 3 (proof over claim —bootstrap validated,
contract exercised by being run rather than by assertion). Purposes 1/2/4 get
the intent-first → ticket → proof chain exercised as validation, not copied.
