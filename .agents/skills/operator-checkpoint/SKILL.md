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
findings) against the live tracker. Drift has no section of its own; it folds
into:
- **NEEDS YOU** when it needs an action (a board row missing for a live item,
  a closed issue with no proof).
- **LIVE** as one board line when it is only information.
- Nothing at all when the board is clean.

Queries:
- `gh issue list --state open --json number,title,labels`
- `gh pr list --state merged --search "merged:>=$date" --base main --json
  number,title,mergeCommit,closedAt` — `--base main` is mandatory; "landed"
  means reachable from main, not merged into an integration branch.
- Closed issues use the anchor **timestamp**, not the date (`closed:>=` is
  date-granular and sweeps in issues closed earlier the same day):
  `gh issue list --state closed --search "closed:>=$isotime" --json
  number,title,closedAt`.
- **Branches ahead of main:** `git rev-list --count origin/main..origin/<b>`.
  Report only branches that need an action; suppress a branch when it is the
  head of an open PR (the PR line covers it) or when another ahead branch
  already contains it (`git merge-base --is-ancestor origin/<b>
  origin/<other>`). Live case: five ahead branches reduce to one line
  (`claude-harness +9`); `t82`/`t84` are contained in it, `t85` is PR #30's
  head, `t31` is PR #32's head.

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
- Closed issues: `gh issue list --state closed --search "closed:>=$isotime"`
  (anchor timestamp, not date). A closed issue with no verification evidence
  and no board row is reported as **proof missing** — and therefore moves to
  NEEDS YOU (live case: #27, closed 09-20 "parked", no proof, absent from the
  board).
- Audit flags: **landed, proof missing**; **landed, checkoff missing** — a
  flagged-risk surface per Deploy §4 (suite-guarded, synced trio, AGENTS.md,
  `docs/agents/`, security/trust boundary, irreversible op) touched, but no
  human checkoff recorded in the thread. An item carrying either flag moves to
  NEEDS YOU; it is never left under CHANGED (live case: `claude-harness +9`).

## 3. Output — one screen

Order follows urgency, matching the operator's four questions: NEEDS YOU,
BLOCKING, CHANGED, LIVE, then NEXT. The operator can stop after the first
section. The header block is a count summary — one count per question, so the
whole picture lands before the first item.

The whole briefing is emitted inside ONE fenced code block (```) so both pi
and Claude Code render it monospace and the column alignment actually aligns.
The fence is also load-bearing: without it, `*` or `_` in a title turns into
italics and a leading `-` becomes a list item.

```
── OPERATOR CHECKPOINT ───────────────────────────────────────────
   run <today> · since <anchor> <anchor-ISO> (<source>)
   needs you <n> · blocked <n> · changed <c> commit(s), <p> PR(s), <i> issue(s)
   live <n> issue(s), <p> PR(s)

── NEEDS YOU (<n>) ───────────────────────────────────────────────

  ! PR      #<n>     <action the human owns>
  ! branch  <name>
                       <why, and what is owed>
  ! issue   #<n>     <action the human owns>

    labels   ready-for-human / needs-info: <#s or none (valid)>

── BLOCKING (<n>) ────────────────────────────────────────────────

    none — all <n> open issues are dispatchable (valid)
    #<n> blocked by #<m> (<owner>)

── CHANGED since <anchor> ────────────────────────────────────────

    <sha>    <subject>
             proof: <direct push to main | mergeCommit.oid>
    #<n>     <title>          proof missing ↑
    PRs merged to main: none (valid)

── LIVE ──────────────────────────────────────────────────────────

    issues    #<n> (PR #<k> ↑) · #<n> ↑ · #<n> needs-triage
    PRs       #<n> <branch> → <base>   awaiting human merge
              #<n> <branch> → <base>   awaiting review
    branches  <n> ahead of main, reducible to <branch> +<m>
    board     <one informational board line, or nothing when clean>

── NEXT ──────────────────────────────────────────────────────────

    <one recommended action — recommendation only, never performed>
```

Rules:
- **Actions live only in NEEDS YOU**, each marked ` ! `. Nothing outside that
  section carries the marker; every `proof missing` and `checkoff missing`
  result belongs there.
- **Each item appears in full exactly once.** Other sections show `#<n> ↑` —
  "details in NEEDS YOU", which is always at the top so the lookup is short.
  `↑` appears only on an item that has its own NEEDS YOU line — an issue
  tracked by a PR references the PR instead: `#31 (PR #32 ↑)`.
- **Empty states are stated, never omitted**: `none … (valid)` on one line.
  A section with no items still prints.
- **Proof sits under its item** on its own indented line: a sha, a
  `mergeCommit.oid`, `direct push to main`, or the words `proof missing ↑`.
- **No line longer than 72 columns** — herdr panes and split terminals are
  often narrower; content that does not fit wraps to a continuation line.
- **Replace any backtick in a title with `'` before output** — three
  backticks inside a title would close the fence early.
- **Counts in words, not abbreviations** — `1 commit, 0 PRs, 1 issue`, never
  `1c 0pr 1i`; the operator asked for clarity first.
- **Type + ref lead every NEEDS YOU row** (`! PR #32`), not owner — the
  operator's own items dominate this section, and the type is what changes
  what they do (open a PR, an issue, or run git). Owner appears in the text
  only when it is not the operator.
- **Every NEEDS YOU item is type-labelled** — `PR`, `issue`, or `branch` —
  so the operator knows where to look before clicking: a bare `#32` is
  ambiguous (GitHub shares one number space across issues and PRs), and the
  live case was exactly that: `#32` read as an issue until the operator
  discovered it was the skill's PR.
- **The LIVE `branches` line always prints** even when every branch is
  suppressed by the action rules (open-PR head, or contained in another ahead
  branch) — the off-main landscape is what the operator watches for growth:
  `<n> ahead of main, reducible to <branch> +<m> (<chain>, PR #<k>)`. Live
  case: `5 ahead of main, reducible to claude-harness +9 (contained in
  t85-dispatch, PR #30; t31 is PR #32's head)`.
- **No colour, no emoji, no closed boxes** — plain text plus `↑`, `·`, `—`,
  and section rules only. Right-edge box padding requires exact character
  counts, which is exactly what an emitting model does badly; rules degrade
  gracefully where closed boxes do not (double-width rendering of `─` in
  East-Asian locales).
- Cut reassurances that ask for no action ("board accurate elsewhere") and
  repeated explanation of why an item is owned by the human — the owner field
  is enough.

## 4. What this is not

- **No writes, ever.** State-changing moves go through `/triage`, the
  orchestrator, or the operator.
- **No QC.** The orchestrator runs acceptance criteria, the suite, and the
  adversary pass per ticket; you read recorded verdicts.
- **No diff review.** That is `code-review`.
- **No second board.** No state file, no snapshot, no side-list.

Wrong tool: per-ticket QC or dispatch → `factory-orchestrator`; triaging new
requests → `/triage`; reviewing a diff → `code-review`.