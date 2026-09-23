---
name: dispatch
description: >
  Dispatch approved work from this conversation: start one fresh,
  worktree-isolated worker per ready-for-agent issue, respect blockers and
  overlapping files, and own progress, QC, lane-sized adversary, merge gates,
  and retirement. Dispatch is automatic — it fires at /build gate 1 whenever
  the live frontier is non-empty, immediately after any approval that leaves
  ready-for-agent work, and on every worker idle notification or QC
  completion, never by background polling. Also use when the developer says
  "go", "dispatch", "work the issues", "start the swarm", or "knock out the
  backlog". Record any missing approval through intent-conversation first.
  The orchestrator coordinates; it does not implement tickets.
---

# Dispatch

Turn "approved" into "built, proven, merged" without being asked twice. The
orchestrating session runs this skill; it never implements a ticket in its own
checkout. A plain "go" approves only the resolved intent in front of you, never
the whole unapproved backlog — that gate is `intent-conversation` Move 3.

Planning, read-only or explicit-pause requests override dispatch. Workers never
recursively dispatch — the worker brief below forbids it.

## Move 1 — Orient

Count open PRs labelled `flagged-risk` or otherwise awaiting a named human
checkoff first — not PRs awaiting your own QC. Nonzero: launch nothing new;
existing workers and the conversation continue.

Frontier = open, labelled `ready-for-agent`, zero open `blocked_by`, not
labelled `ready-for-human`, not `wontfix`. Fetch every page. Read each
candidate's blocker summary (`gh api repos/{owner}/{repo}/issues/<n>`); missing
or errored data means unknown, not zero — skip it this pass. Require the
issue's intent file to exist and cite the issue; an uncommitted or missing
intent is not a worker brief. Re-check the frontier immediately before each
launch, not just at the top of the move.

An operation that provisions, first-deploys, migrates or changes identities
stays human-run even if labelled — never dispatched (ADR-001 D5).

## Move 2 — Batch

Read `**Touches:**` from each candidate's `intent.md` — a JSON array of
repo-relative paths/globs. Missing, malformed, empty or unbounded means
unknown. Prove pairwise disjointness against other candidates **and** active
workers; prefix/glob ambiguity means overlap. Contract producer/consumer pairs
run in sequence even when disjoint.

Concurrency: 2 workers by default, 1 when any candidate's Touches are unknown
or overlapping, 0 new launches while any PR waits on a human gate. The
developer can change this in plain language for the rest of the conversation.

Reserve issue, branch, worktree path, Touches, base SHA, worker/session id, PR
and state under the repo's own ignored `.factory/` directory before launching.
Reconcile against Git/worktrees/PRs before retrying or re-entering after a
restart; never double-launch. This is local recovery state, not a second
tracker.

## Move 3 — Dispatch

Branch name is always `t<n>-<slug>`. Detect and use, in this order: your
harness's own session-creation tool; else a child headless session in a
worktree; else a sub-agent with worktree isolation. A sub-agent over a shared
checkout is never a worker, whatever the host.

### Mechanics by capability

| Capability | Launch | Watch / steer |
|---|---|---|
| Desktop app with a session-creation tool (`create_session`) | Worktree workspace, autopilot kickoff carrying the worker brief below, coordinated with the creator, notified on idle. The worker renames its own branch to `t<n>-<slug>`. | Idle notification; its own session-inspect/session-message tools; keep the returned session id. |
| CLI with headless child sessions (`--worktree`) | A child headless session in its own worktree on branch `t<n>-<slug>` (verify: sibling worktree, exact branch). A shared-checkout sub-agent is not a worktree and may be used only after you have created the worktree yourself, or not at all. | Process completion and structured output; resume the exact session id, not an ambiguous "continue latest". |
| Harness with a worktree-isolating sub-agent tool (its own worktree option) | Its documented worktree-isolation and background-completion mode; the worker checks out or creates `t<n>-<slug>`. | Its native completion/message/resume tools; keep the returned identifier. |

Before real unattended work, confirm in that exact worktree — never infer from
the parent — that a guardrail source is verifiably loaded: the plugin's own
enforcement hooks or the repo's committed hooks. Prove it with a harmless
denial: the worker's first turn runs one infra-flavoured command (for example,
a cloud CLI read like `az account show` or a destructive-looking dry run) that
a loaded guardrail must deny. If nothing denies it, that issue runs serially in
the supervised parent instead of unattended — do not relax this to get a
worker running.

## Move 4 — Watch

Report launches, blocked/stalled workers, PR handoffs, gate results and
retirements in this conversation as they happen. An idle worker with no
`HANDOFF:` line is not success — send it a concrete same-ticket correction,
never a new issue for the same scope.

## Move 5 — QC

Run yourself, on the worker's branch, never by switching the developer's busy
checkout: the ticket's acceptance commands, then `bash tests/validate.sh
origin/main..HEAD` (record base/head SHAs, full output, exit code and lane
line). Compare the actual diff's paths to its Touches; expansion pauses
conflicting work for re-batching. Review against the ticket's spec and this
repo's review policy. A fix needs fail-first evidence. If the branch is stale,
the worker rebases and proof reruns before merge.

This one check folds in the lane's review (ADR-002): T2 one read-only
adversary pass, T1 one bounded pass over the diff's own claims (MED+ only), T0
none — `adversary: n/a — T0` plus the filled `no-ADR=<y/n>
not-speculative=<y/n>` line. Escalate a lane, never lower it. Two consecutive
QC failures across the chain halt new launches until the developer weighs in.

**Merge gate is light.** Green `validate` plus this one QC check merges — no
further review rounds. `flagged-risk` merges only on a named human checkoff.
Send unresolved findings back to the same worker, never to a new one. When the
QC check passes, the orchestrator merges: `gh pr merge --squash --delete-branch
<pr>`. Workers never enable auto-merge on ticket PRs — that would land a
change before this check runs.

## Move 6 — Retire

Confirm `gh pr view <pr> --json state` is `MERGED` and the worktree has
nothing uncommitted or unpushed. CLI/other-host worktrees: `git worktree
remove <path> && git branch -D <branch>`. App workspaces without an archive
tool: report "retire pending in app", never delete from disk. Withdrawn or
failed work keeps its branch and worktree until separately authorized cleanup.

## Move 7 — The conversation keeps flowing

New requests route to `intent-conversation` while workers run; every approval
that leaves `ready-for-agent` work re-enters Move 1 automatically. A decision
settled mid-conversation routes to `intent-conversation` Move 2b in the same
turn, never held until workers finish. Every worker
idle notification and every QC completion also re-enters Move 1 — not only
approvals. Report what landed, active workers, gate results and retirements
without making the developer open another surface. Never overwrite
uncommitted parent work or silently mutate a running worker's brief.

## Worker brief (send this, filled in, as the kickoff prompt)

> You are the worker for issue #<n> only in <owner/repo>, worktree
> <absolute-path>, expected branch `t<n>-<slug>`, approved base `<sha>`. You
> implement; your creator orchestrates. Do not load `dispatch` or start
> another ticket from here.
>
> First turn: run `<harmless infra command>` and confirm it is denied by a
> loaded guardrail before doing anything else. If it is not denied, stop and
> report that instead of continuing unattended.
>
> Read `AGENTS.md`; then `gh issue view <n> --comments`, the named spec and
> intent, every cited ADR, `CONTEXT.md`, and only then the code. A missing
> link, spec or ADR: stop, say what is missing on #<n> and in `HANDOFF:`,
> never improvise around it.
>
> Pre-answered ambiguities: <2-3 decisions the orchestrator already settled>.
> Allowed Touches: <paths>. Concurrent reservations: <other issues/paths in
> flight>. Tell the orchestrator before expanding scope.
>
> Before editing, verify `git rev-parse --show-toplevel` and `git branch
> --show-current` land you in your own worktree on your own branch. If
> `git branch --show-current` is not `t<n>-<slug>`, rename it (your harness's
> branch-rename tool, or `git branch -m`) or create it from `<sha>` before
> editing. Never force an existing branch, write in the creator's checkout,
> commit to `main`, or push `main`.
>
> No keys in code or `.env`. No provisioning, deploy, migration or identity
> operation — cite platform ADRs, never re-decide them. Test-first, shortest
> complete diff, no speculative abstractions.
>
> Run and paste the ticket's acceptance commands and `bash tests/validate.sh
> origin/main..HEAD` (exit 0, with its lane line). Fixes carry fail-first
> proof. Rebase a stale base and rerun before you say you're done.
>
> Record any decision this ticket needs an ADR for, under this repo's
> ownership rules, in this PR — never invent an approval. Commit and push only
> your branch; open the PR to `main` with a body file carrying the same proof,
> and paste it on #<n> too. Do not merge or close the issue.
>
> Stay available for QC/adversary corrections on this same issue after
> handoff. End your final message with:
> `HANDOFF: ticket #<n> | pr=<url or none> | pushed=<sha range or none> | ADRs=<ids or none> | followups=<one line or none>`
