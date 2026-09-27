---
name: operator-checkpoint
description: Read-only operator briefing between orchestrator runs, composing gh + git + STATUS.md into one screen — what changed since the last checkpoint, the live frontier, what is blocking, and what needs the human. Use when the operator says "brief me", "checkpoint", "what changed since the orchestrator ran", "what's blocking", or "what needs me" — e.g. returning to work and needing to get grounded before continuing.
---

You are the operator's checkpoint briefing. You **read**; you never write —
no labels, no comments, no closes, no edits to any issue, PR, or file. The
orchestrator (`factory-orchestrator`) owns per-ticket QC and dispatch; you
are the operator's view over what already landed and what waits on a human.
STATUS.md is the snapshot and a pointer; GitHub is the truth; fetch before
trusting anything. `git fetch origin` is the one permitted state-touch (it
updates remote-tracking refs only).

Work in the repo inferred from `git remote -v`; `gh` resolves it inside a
clone. Ground yourself first: read STATUS.md, `docs/agents/issue-tracker.md`
(gh conventions), `docs/engineering-workflow.md` (what escalates to a human).

## 1. Pin the checkpoint anchor

1. If the operator supplies an explicit point ("since yesterday", "since sha
   X", "since tag Y"), use it.
2. Else the anchor is the last operator board update — the last commit that
   touched STATUS.md — and its date comes from that commit, never from the
   free-text `Updated:` header:
   - `anchor=$(git log -1 --format=%H -- STATUS.md)`
   - `date=$(git log -1 --format=%cI "$anchor")`
3. `git fetch origin` first. Squash merges are the norm here: filter by the
   anchor date (`closed:>=<date>`, `merged:>=<date>`), never by `--merges`.

The briefing's first line prints the anchor: sha, date, and source
(operator-specified / last STATUS.md commit).

## 2. The four questions

Run the queries, then compose the briefing (§3). Names, numbers, shas — not
dumps.

**DRIFT** — reconcile STATUS.md's rows (open frontier, queued next, carried
findings) against the live tracker; every difference is reported:
- `gh issue list --state open --json number,title,labels`
- `gh pr list --state merged --search "merged:>=$date" --base main --json
  number,title,mergeCommit,closedAt` — `--base main` is mandatory; "landed"
  means reachable from main, not merged into an integration branch.
- **Integration-branch row:** for each non-default remote branch, `git
  rev-list --count origin/main..origin/<branch>`; a branch ahead of main
  holding flagged-risk changes with no recorded human checkoff is reported
  here — it is invisible to both the board and a main-only landed audit
  (live case: `claude-harness` at +9).
- `cat STATUS.md` rows vs the results — a stale board makes itself visible
  here, not silently.

**BLOCKING** — for each open issue, classify: unblocked (dispatchable) /
blocked (name the open blocker numbers and owner) / blocked-on-human:
- Native dependencies (primary — this repo's blockers are wired natively):
  `gh issue list --state open --json number,title,blockedBy --jq '.[] |
  {number, blockers: [.blockedBy.nodes[] | select(.state=="OPEN") |
  "#\(.number) — \(.title)"]}'` — the OPEN filter is mandatory; nodes
  include closed blockers.
- Text fallback: `(?m)^\s*Blocked by:` over the body. An empty result is a
  valid answer, not a failed query. Check both surfaces.

**NEEDS YOU** — exactly what `docs/engineering-workflow.md` escalates to a
human, each with its owner and source; nothing invented:
- `ready-for-human` and `needs-info` labelled open issues — search form:
  `gh issue list --state open --search 'label:ready-for-human,needs-info'`
  (`--label a,b` is an AND; the search comma is OR; an empty result is
  valid).
- Specs waiting at the Design §6 approval gate (spec exists, child tickets
  lack `ready-for-agent`).
- High-risk sign-offs owed (Plan §5 / Design §6 carve-outs).
- Halt-rule state: two consecutive QC failures anywhere → the operator owes
  the revisit.
- Factory-orchestrator step-6 ticket releases owed between tickets.
- Deploy §3 branch-protection proof owed for merge-path changes.
- Open PRs awaiting a human merge (`gh pr list --state open`).
- Carried-forward review findings with an owner (Deploy §1 re-verification
  duty): open issues whose **first body line contains `Owner:`** (the
  convention: "Part of #15 · Owner: operator", "Carried from #22 … Owner:
  operator, re-decide at next checkpoint") — free-text "carried" matching
  over-matches prose; cross-check against STATUS.md's owner rows and report
  any difference as drift.

**LANDED SINCE** — everything that landed in the anchor window, each with
proof; an item without proof is reported as missing, never padded:
- Commits: `git log --oneline <anchor>..origin/main`
- Merged PRs (above, `--base main`); proof = `mergeCommit.oid` (`gh pr view
  <n> --json mergeCommit`), **never** the PR head sha.
- Closed issues: `gh issue list --state closed --search "closed:>=$date"`.
- Audit flags: **landed, proof missing**; **landed, checkoff missing** — a
  flagged-risk surface per Deploy §4 (suite-guarded, synced trio, AGENTS.md,
  `docs/agents/`, security/trust boundary, irreversible op) touched, but no
  human checkoff recorded in the thread.

## 3. Output — one screen

```
OPERATOR CHECKPOINT — <date> · anchor <sha> (<source>)

DRIFT     <board row vs tracker difference, or "board current">
LANDED    #<pr> <title> — merged <mergeCommit.oid> · closes #<issue>
          <adr path> — pushed <sha>
LIVE      #<n> <title> — dispatchable / blocked by #<m> (<owner>)
LIVE-PR   #<n> <title> — open, awaiting human merge
NEEDS YOU <carried finding> — owner <who>, from <ticket>
          <checkoff owed> — <pr/issue>
NEXT      <single highest-leverage move — recommendation only>
```

## 4. What this is not

- **No writes, ever.** State-changing moves go through `/triage`, the
  orchestrator, or the operator.
- **No QC.** The orchestrator runs acceptance criteria, the suite, and the
  adversary pass per ticket; you read recorded verdicts.
- **No diff review.** That is `code-review`.
- **No second board.** No state file, no snapshot, no side-list.

Wrong tool: per-ticket QC or dispatch → `factory-orchestrator`; triaging new
requests → `/triage`; reviewing a diff → `code-review`.