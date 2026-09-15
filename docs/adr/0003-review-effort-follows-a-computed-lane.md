# Review effort follows a computed lane, and the lane is computed by the gate

**Issue:** (pending — Sean files on `smcozart/cozyharness`; landed on branch `claude-harness`, not `main`) · **Status:** proposed · **Intent:** the arti-agent-platform retro `.factory/retro-scaffold-speed.md` (2026-09-15) and its `improvements` pane review; the intent dir follows the issue number.

The adversary pass was mandatory on every agent-produced diff, and the light
lane (#24) was a nine-clause predicate an agent evaluated by hand. Together
those produced the cost the platform measured on 2026-09-14/15: a two-file,
+10/−2 board PR (#88 there) drew a full adversary report roughly fifty times
its diff, half of whose findings were copy-edits; and because no one trusted
the hand-evaluated lane, the safe default was always the full pass. Nothing
in the loop tiered verification to the change.

**Decision.** Review effort is a function of a **lane**, and the lane is
**computed by the Test gate**, not judged. `tests/validate.sh --lane <range>`
classifies the diff from what git can see — file count, paths against a
protected set, changed lines, whether the board was touched — and prints one
`lane:` line pasted beside the gate run. **T0** (≤2 docs files, nothing
protected): the gate run is the review, no adversary pass. **T1** (≤2 files,
≤60 lines, unprotected — or any touch of `STATUS.md`, the first file a session
reads): one bounded adversary pass, the diff's claims only, MED+ findings.
**T2** (any protected surface, >2 files or >60 lines): the full loop as
before. Two clauses git cannot see stay with the agent and are stated at
close — *earns no ADR*, *not speculative* — and **escalation is the only
direction**: an agent may raise a computed lane, never lower it. Consumers
extend the protected set with the surfaces their own checks guard; a consumer
whose protected set is empty has not adopted the lane. The classifier is a
mode, not a check — it never fails and is not in `--list` — but it carries
witnesses in `--witness` (four historic ranges, two mutations) because a wrong
lane is a wrong review budget.

**Rejected.** *Keep "adversary on everything"*: correct when it caught 13
defects in a two-file skill PR, but it cannot distinguish that PR from a typo
fix, and the cost grows with every parallel worker. *Let the agent pick the
tier*: that is the predicate this replaces; an untrusted judgement produces
the full pass by default. *`merge=union` / skip review for docs*: docs here
are executable — a SKILL.md tells agents what to run — which is exactly why
the protected set, not the file extension, decides T2.

**Consequences.** T0 closes with no adversary artifact at all; that is
deliberate and the `lane:` line is the record of why. The thresholds (2
files, 60 lines) are starting values, changed by amending this ADR with the
evidence. The synced trio, `REVIEW.md` and `AGENTS.md ## Commands` changed in
the same commit; the platform's `herdr-factory` QC step 3 ("adversary pass
mandatory") follows as a consumer PR, and the orchestrator's standing rule
"adversary on every PR incl. docs" becomes "at T2, bounded at T1".
