# Decisions are records in the same turn, and intake never waits

**Issue:** (pending — Sean files on `smcozart/cozyharness`; landed on branch
`claude-harness`, not `main`) · **Status:** proposed · **Decision owner:**
Sean Cozart · **Intent:** arti-build issue #77 ("decisions become records"),
narrowed for this repo by arti-build-plugin issue #82.

Upstream (arti-build #77), a developer's session settled a design decision in
conversation and left it there — parked in chat, promised for a later batch
update — instead of landing it in the artifact the loop reads. The decision
was real, but nothing durable held it: no ADR, no spec edit, no ticket body
line, so the next session (or the next reviewer) had no record to read, only
a transcript to re-derive it from.

**Decision.** A settled decision — "let's go with X", "lock that in", "we
decided" — becomes a record in the same turn it is settled, before the next
question, never held for later batching. It lands by kind: a hard-to-reverse
or authority rule becomes a new ADR in `docs/adr/NNNN-slug.md`; a requirement
or design detail becomes an edit to the spec's matching section; a detail
scoped to one ticket becomes an edit to that issue's body. The developer's
in-conversation settling of the decision is its approval — no separate
sign-off beyond the Design approval gate's high-risk carve-out. Paired with
this: intake never waits — filing a new request is never gated by running
workers, an open blocker, or a foundation ticket in flight; a dependent
request is filed as its own issue with a blocking edge to the one ahead of
it (mechanics: `docs/agents/issue-tracker.md`).

**Consequences.** Design item 7 / SKILL.md item 5 states the rule and the
record locations only; the records-worktree mechanics (a per-conversation
branch that commits, pushes, and PRs itself) belong to a skill, not this
doc, and arrive in a later ticket. Until that skill lands, recording a
decision this way is manual. The synced trio
(`docs/engineering-workflow.md`, `plugin/skills/engineering-workflow/SKILL.md`,
`README.md`) changed together in this commit per the sync rule.
