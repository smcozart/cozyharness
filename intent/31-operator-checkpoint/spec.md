# Spec: operator-checkpoint skill

**Issue:** #31 · **Intent:** `intent/31-operator-checkpoint/intent.md`

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

**BLOCKING (Q2):** for each open issue, parse native dependencies AND
`Blocked by:` body lines. Native is the primary surface (#17 wired blockers
this way):

    gh issue list --state open --json number,title,blockedBy \
      --jq '.[] | {number, blockers: [.blockedBy.nodes[] | select(.state=="OPEN") | "#\(.number) — \(.title)"]}'

`blockedBy.nodes[]` yields `{number, state, title, url}`; the
`select(.state=="OPEN")` filter is mandatory — nodes include closed blockers,
and without it a finished blocker reports as live. Text fallback:
`(?m)^\s*Blocked by:` (multiline) over the body. Classify: unblocked
(dispatchable) / blocked (open blocker numbers + owner) / blocked-on-human.
An empty result is a valid answer, not a failed query.

**NEEDS YOU (Q3)** — exactly what `docs/engineering-workflow.md` escalates,
each item **type-labelled** (`PR` / `issue` / `branch` — GitHub shares one
number space, so a bare `#32` is ambiguous):
`ready-for-human` and `needs-info` issues; specs waiting at the Design §6
approval gate; high-risk sign-offs owed (Plan §5 / Design §6); halt-rule state
(two consecutive QC failures → operator); factory-orchestrator step-6 ticket
releases owed; Deploy §3 branch-protection proof owed; open PRs awaiting a
human merge; carried-forward findings with owners, sourced from open issues
whose **first body line contains `Owner:`** (the carried-findings convention:
"Part of #15 · Owner: operator", "Carried from #22 … Owner: operator,
re-decide at next checkpoint"); cross-check the result against STATUS.md's
owner rows and report any difference as drift. Free-text matching of
"carried" in bodies over-matches (matched #31's prose) — do not use it
(Deploy §1 re-verification duty).

Label queries use the search form — `gh issue list --state open --search
'label:ready-for-human,needs-info'` — because `--label a,b` is an AND, not an
OR; both labels absent from every open issue is a valid empty result.

**LANDED SINCE (Q4):** commits (`git log --oneline <anchor>..origin/main`),
merged PRs (`gh pr list --state merged --search "merged:>=" --base main`; proof =
`mergeCommit.oid`, never the PR head sha), closed issues since the anchor.
Two audit flags: **landed, proof missing** and **landed, checkoff missing**
(a flagged-risk surface per Deploy §4 touched, but no human checkoff recorded
in the thread).

**DRIFT also carries an integration-branch row:** any remote branch ahead of
main (`git rev-list --count origin/main..origin/<branch>` for non-default
remote branches). A branch holding flagged-risk changes with no recorded
human checkoff — work invisible to both the board and a main-only landed
audit — is exactly what NEEDS YOU exists to surface.

**LANDED (Q4) means reachable from origin/main.** Without `--base main`, the
audit counts merges into integration branches as landed — those are the
integration-branch row's business, not Q4's.

## Section 3 — output shape

One screen, urgency-first (the operator's four questions in order): a header
line, a one-line count summary, then **NEEDS YOU / BLOCKING / CHANGED / LIVE
/ NEXT**. Actions live only in NEEDS YOU (` ! ` marker); each item appears in
full exactly once and elsewhere as `#<n> ↑`; empty states print `none …
(valid)`; every CHANGED row carries its proof in a fixed column (sha,
`mergeCommit.oid`, `direct push`, or `proof missing ↑`). Drift has no section
of its own — it folds into NEEDS YOU (action owed), LIVE (one informational
board line), or nothing when clean. Branches ahead of main report only when
an action is owed: suppress a branch that is an open PR's head or that
another ahead branch contains (`git merge-base --is-ancestor`). The LIVE
`branches` line always prints — even when every branch is suppressed — so the
operator can watch the off-main landscape for indefinite growth. Plain text
plus `↑` only — no colour, no emoji. The next action is a recommendation; the
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