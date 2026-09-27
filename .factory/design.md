# Factory build — Deploy stage of the Harness

The Harness is at Deploy. Plan (#2), Design (#3), Build (#4), Test (#9) are
closed with proof; their contracts live in `docs/engineering-workflow.md`
(+ synced plugin skill + README). This build executes the Deploy-stage work
item: parent **#12**, spec `intent/12-deploy-stage/spec.md` (approved,
adversary-folded), sequence `intent/12-deploy-stage/plan.md` (approved).

## Definition of done

#12 closes when every child (#13, #14) is closed with pasted proof: T1's
`REVIEW.md` + T2's one-sha landing (Deploy section + synced trio +
stage-parity 555 + three mutation witnesses + CONTEXT.md terms). Any
hard-to-reverse decision lands as ADR 0003 in `docs/adr/`, pushed
immediately — none expected; never write an `ADR <number>` reference to an
unwritten ADR anywhere `adr-refs` greps.

## Live frontier

GitHub issues labeled `ready-for-agent`. Nothing in a file outranks it.

```
gh issue list --label ready-for-agent
```

## Ticket breakdown

- #13 T1: `REVIEW.md` policy artifact — four `##` sections (passes /
  severity / skip-list / loop), nothing else touched. Labeled
  `ready-for-agent`. **First.**
- #14 T2: Deploy section + synced trio + stage-parity 4→5 + three mutation
  witnesses + CONTEXT.md terms, **one sha**. **blocked_by #13.**

Hooks (#1) out of scope. No PR flow — the merge gate binds to ticket closes
until #1 or a consumer need changes that.

## Orchestrator

- Pane id: `w1:p3E` (workers send their `HANDOFF:` ping here; verify via
  `herdr agent list`).
- Model policy (operator, supersedes the kimi-k3 pin): **auto-routed, no
  pin**; pin a smarter model per ticket only if QC shows it warrants it;
  Fable stays unused. Track spend qualitatively (auto's cost display is
  broken-by-registry).
- QC: reproduce acceptance criteria by hand + review the diff against the
  spec + mandatory `adversary` subagent (`agentScope: "project"`) per diff
  before blessing. For T1, the review + adversary verdicts are also part of
  the ticket's own proof (the close runs the loop REVIEW.md defines).
- Halt rule: two consecutive QC failures → stop the chain, revisit with the
  operator.
- Checkpoint: operator releases each ticket; report after T1 QC before
  dispatching T2.

## Scope constraints

- Sync rule: any `docs/engineering-workflow.md` change hits
  `plugin/skills/engineering-workflow/SKILL.md` + `README.md` in the same
  commit. REVIEW.md is NOT a fourth synced file.
- `tests/validate.sh` stays offline (Test §5); the T2 edit touches only
  stage-parity's alternations, the `444`→`555` literal, and witness rows.
- T2 is one commit — doc + SKILL + README + check + witnesses together
  (sync execution rule; Test §4).
- Label vocabulary: the five canonical triage labels only.
- Issues #2/#3/#4/#9 closed — do not reopen their contracts.

## The worker dispatch contract (per ticket)

1. **Orient:** `gh issue list --label ready-for-agent`; read the ticket in
   the Design §7 order (ticket → spec → intent → ADRs → CONTEXT.md → code).
2. **One ticket per session** — fresh herdr pane, never reused.
3. Worker implements, closes the issue with pasted proof, and ends with a
   `HANDOFF:` ping to pane `w1:p3E`.
4. Orchestrator runs QC (acceptance criteria reproduced by hand) plus an
   `adversary` pass on the diff before blessing.
5. Two consecutive QC failures anywhere → halt the chain.
6. Checkpoint with the operator between tickets; operator releases the next.

## Worker prompt template (per ticket)

> You are a Deploy-stage worker in the cozyharness factory build. Work
> GitHub issue #N ONLY (`gh issue view N`).
>
> Process contract (non-negotiable):
> 1. Read `.factory/design.md` first, then the ticket in the Design §7
>    order: ticket → spec (`intent/12-deploy-stage/spec.md`, via the path
>    in the ticket body) → intent → ADRs → CONTEXT.md → code.
> 2. Implement exactly the ticket's deliverable. Lean — shortest working
>    diff, no speculative abstractions, no extra files. T2 is ONE commit.
> 3. If the ticket's spec or links are missing: bounce it back with a
>    comment saying what's missing. Do not improvise.
> 4. ADRs: a decision that is hard to reverse, surprising, or a real
>    trade-off gets a one-paragraph `docs/adr/NNNN-slug.md`, committed and
>    pushed. None expected for #13/#14.
> 5. Before closing: review your own diff against every acceptance
>    criterion, push, and close #N with a comment pasting the verification
>    commands and output. Proof over claim.
> 6. Go idle. Do NOT start any other ticket.
> 7. Final ping (orchestrator spins the pane down after this): run
>    `herdr agent prompt w1:p3E "HANDOFF: ticket #N | closed=<yes/no> |
>    pushed=<sha range> | ADRs=<ids or none> | followups=<one line or
    none>"`. Also leave the same line as your last in-buffer message. Then
>    idle.
>
> [Pre-answered ambiguities, ticket-specific, go here — copy from
> plan.md's "Pre-answered ambiguities" section.]
