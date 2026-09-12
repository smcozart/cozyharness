# Plan: Build stage tickets (from intent.md — operator-approved)

## Files that change (by ticket)

- T2 bootstrap: `bootstrap.sh` (fixes only if run reveals defects), issue comment
  carries pasted output.
- T1 orchestrator mechanics: `plugin/skills/factory-orchestrator/SKILL.md` and
  `.agents/skills/factory-orchestrator/SKILL.md` — both copies, byte-identical,
  one commit.
- T3 override note: `AGENTS.md` (pointer location per operator), no new docs.

## Order of work

Three independent tickets, no blocking edges — none touch shared files (T3's
candidate AGENTS.md edit does not overlap T1's skill files; T2 touches only
bootstrap.sh). Recommended queue to minimize review overhead: T2 → T1 → T3.
Each closes with pasted proof; parent #4 closes after the reverse-wiring
summary.

## Risks

- T1 appendix must stay honest for Claude Code AND Codex hosts — speculative
  breadth is the failure mode (small, verifiable commands per host).
- T2 bootstrap run mutates `.agents/skills/` (re-copy from upstream); run on a
  disposable checkout or accept-and-verify idempotence, and diff before closing.
- T3 could drift into rewriting the engineering-workflow doc; surface any
  sync-rule-relevant edit at the checkpoint instead of the ticket scope.

## Proof

Per ticket on its issue: T2 paste of the bootstrap run's full output; T1
`diff` (empty) between both copies + appendix section listing host commands;
T3 grep-able AGENTS.md override lines. Reverse-wiring comment on #4 closes
the parent.
