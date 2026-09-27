# Intent: operator-checkpoint skill (#31)

**Issue:** #31 · **The one sentence:** the operator has no fast, trustworthy way to answer "what
changed, what's blocking, what needs me" between orchestrator runs — this skill
is the read-only briefing that composes gh + git + STATUS.md into one screen.

**Why now:** the write side of the checkpoint contract exists (factory-
orchestrator step 6 reports between tickets; Deploy §1 re-verifies carried
findings "at the next operator checkpoint") but nothing defines the reader
side. Proven live: STATUS.md sat 10 days stale while #28/#29 merged and #30
opened, unreflected — drift with no detector.

**Outcome:** invoking the skill ("brief me" / "checkpoint" / "what needs me")
produces a one-screen briefing — anchor, drift, landed-with-proof, live
frontier, needs-you list, one recommended next action — without writing
anything.

**Non-goals:** no writes of any kind; no per-ticket QC (factory-orchestrator's
job); no diff review (code-review's job); no second board (STATUS.md stays the
pointer, GitHub stays the truth); no CI automation (waits on #1).

**Scope:** one new file, `.agents/skills/operator-checkpoint/SKILL.md`. Single
copy for now — mirror to plugin/.claude copies only when the Claude-host pilot
needs it, extending skill-copies in the same diff. Flagged-risk surface
(Deploy §4) → human checkoff at close regardless of size; lands via PR (branch
protection active).

**Design provenance:** structure agreed between the orchestrator session and a
Claude side-reviewer herdr session (pane w1:p3Y), which corrected the anchor
mechanism (commit sha, not free-text date), the trigger collision ("where are
we" belongs to factory-orchestrator), the Q3 list (workflow-backed items only),
and added the proof-discipline flags.