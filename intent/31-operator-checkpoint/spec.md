# Spec: operator-checkpoint skill (#31)

The skill is a **read-only composer**. It reads; it never writes — no labels,
no comments, no closes, no edits to any issue, PR, or file. `git fetch origin`
is the one permitted state-touch (remote-tracking refs only) and is stated as
such in the skill body. STATUS.md stays the single live board and a pointer to
GitHub; the skill creates no state file, no snapshot, no side-list.

## Frontmatter

Single-line `name: operator-checkpoint` and single-line `description:` naming
the trigger phrases (the skill-frontmatter check requires this shape): "brief
me", "checkpoint", "what changed since the orchestrator ran", "what's
blocking", "what needs me". Never "where are we" (owned by
factory-orchestrator).

## Section 1 — the anchor

1. If the operator supplies an explicit point ("since yesterday", "since sha
   X", "since tag Y"), use it.
2. Else the anchor is the last operator board update:
   `git log -1 --format=%H -- STATUS.md`; its date comes from that commit
   (`git log -1 --format=%cI <anchor>`), never from the free-text `Updated:`
   line.
3. Run `git fetch origin` before any query. Squash merges are the norm here:
   "what changed" filters by the anchor date (`closed:>=<date>`,
   `merged:>=<date>`), never by `--merges`.

The briefing's first line prints the anchor: sha, date, source.

## Section 2 — the four questions

**DRIFT (Q1):** reconcile STATUS.md's rows (open frontier, queued next,
carried findings) against the live tracker (`gh issue list --state open`,
`gh pr list --state merged` since the anchor, labels). Every difference is
reported; a stale board makes itself visible.

**BLOCKING (Q2):** for each open issue, parse `Blocked by:` body lines AND
native dependencies (`gh api repos/<owner>/<repo>/issues/<n> --jq
.issue_dependencies_summary.blocked_by`). Classify: unblocked (dispatchable) /
blocked (name open blocker numbers + owner) / blocked-on-human.

**NEEDS YOU (Q3)** — exactly what `docs/engineering-workflow.md` escalates:
`ready-for-human` and `needs-info` issues; specs waiting at the Design §6
approval gate; high-risk sign-offs owed (Plan §5 / Design §6); halt-rule state
(two consecutive QC failures → operator); factory-orchestrator step-6 ticket
releases owed; Deploy §3 branch-protection proof owed; open PRs awaiting a
human merge; carried-forward findings with owners, sourced from open issues
carrying a carried-forward note (Deploy §1 re-verification duty).

**LANDED SINCE (Q4):** commits (`git log --oneline <anchor>..origin/main`),
merged PRs (`gh pr list --state merged --search "merged:>="`; proof =
`mergeCommit.oid`, never the PR head sha), closed issues since the anchor.
Two audit flags: **landed, proof missing** and **landed, checkoff missing**
(a flagged-risk surface per Deploy §4 touched, but no human checkoff recorded
in the thread).

## Section 3 — output shape

One screen, in order: ANCHOR / DRIFT / LANDED (with proof) / LIVE (frontier) /
NEEDS YOU / ONE NEXT ACTION. The next action is a recommendation only — the
skill performs no action.

## Section 4 — non-goals and wrong-tool pointers

No writes; no QC (factory-orchestrator); no diff review (code-review); no
second board. Wrong tool for: per-ticket QC or dispatch → factory-orchestrator;
triage → /triage; reviewing a diff → code-review.

## Acceptance criteria

- Anchor logic per §1; anchor printed on line 1 of every briefing.
- Drift check per §2 Q1; blocking classification per Q2; needs-you list
  matches the workflow escalations exactly (nothing invented, nothing from
  the pre-review draft retained); landed items carry proof or are flagged.
- Read-only: the skill body contains no state-changing command; `git fetch
  origin` is the only exception and is called out.
- `tests/validate.sh` green with the new file present (skill-frontmatter
  passes; skill-copies unaffected — single copy).
- A manual run against live repo state produces the one-screen briefing.