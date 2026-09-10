# Contributing

This repo runs on its own process — contributions go through the same loop the
process defines. That's deliberate: it keeps the bar honest and dogfoods the
system.

## The loop

1. **Intent first.** Open an issue stating the problem, the desired outcome
   (not a task list), scope, and non-goals. Changes without a clear why get
   sent back to Plan.
2. **Triage.** Issues move through the triage labels (`needs-triage`,
   `needs-info`, …) until they earn `ready-for-agent` = blockers resolved +
   acceptance criteria defined. See `docs/agents/`.
3. **Tickets with edges.** Multi-part changes become vertical-slice ticket
   issues with blocking edges declared in issue bodies.
4. **Build** test-first and lean: stdlib first, shortest working diff, no
   speculative abstractions (the vendored `ponytail` skill enforces this
   posture — work with it).
5. **Proof over claim.** Closing an issue requires pasting the verification
   commands and their output. PRs pass review: standards + spec, plus an
   adversarial pass on agent-produced diffs.
6. **ADRs.** If your change is hard to reverse, surprising without context, or
   a real trade-off, add `docs/adr/NNNN-slug.md` in the same PR — committed
   with the change, never after.

## The sync rule (non-negotiable)

The process lives in three places that must never drift: `docs/engineering-workflow.md`
(canonical), `plugin/skills/engineering-workflow/SKILL.md` (Claude bundle), and
`README.md` (the pitch). A PR that changes the process updates all three in the
same commit.

## Local setup

```bash
./bootstrap.sh
```

See `plugin/README.md` for the full adoption order and dependencies.