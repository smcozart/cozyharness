---
name: engineering-workflow
description: The standard engineering process for this org — use when starting any engineering work (new project, feature, or bug fix), when planning, ticketing, triaging, implementing, reviewing, or recording decisions. Defines the six-phase loop (Plan/Design/Build/Test/Deploy/Maintain) and its contracts.
---

# Engineering Workflow

The standard process. Applies to every unit of work: new system, feature, or
bug fix. Six phases; each resolves to a durable artifact, mostly GitHub objects.

```
Plan → Design → Build → Test → Deploy → Maintain ──► back to Plan
```

## Phase 0: Prerequisites (once per repo)

1. `gh` authenticated — GitHub Issues is the tracker; issue numbers are the
   join key between humans, sessions, and machines.
2. If the repo has no triage labels yet or no `docs/adr/`, run
   `/setup-matt-pocock-skills` before anything else. It scaffolds the per-repo
   config the other skills assume: tracker location, the triage label
   vocabulary (ending in `ready-for-agent`), and domain doc layout
   (`CONTEXT.md`, `docs/adr/`). Without it, to-tickets and triage have no
   defined destination. Run once per REPO, not per machine.
3. Onboarding order for a fresh session on an existing repo: read `CLAUDE.md` or
   `AGENTS.md` if present, then `docs/engineering-workflow.md` → `gh issue list --label
   ready-for-agent`. That sequence reconstructs full context from the repo
   alone — never from chat history.

## Plan — issue-first intake, intent & the why

Every request becomes a GitHub issue **first** — problem, desired outcome,
scope, non-goals. Multiple requests in one conversation split into separate
issues (with blocking edges if related); one request, one issue, no side-lists
in chat.

After triage clarification, capture the agreed why as **work-item intent** at
`intent/<issue-number>-<slug>/intent.md` (template: `intent/TEMPLATE.md`). The
issue number joins issue, intent, branch, PR, and proof. Check the intent
against `SYSTEM-INTENT.md` (the system's enduring purpose) — conflicts amend
it deliberately or rewrite the intent. Bug fixes seed the intent from the
diagnosis; features from the brief; PRDs from transcripts.

**Approval:** normal work is approved conversationally in the issue thread
(`ready-for-agent` = approved to proceed). High-risk work (security, data
loss, irreversible migrations, public contracts) requires explicit human
review sign-off in the issue, recorded as an ADR. No approved intent, no work.

The intent is the lighthouse — everything downstream is graded against it.
The Plan artifact is the intent; any `plan.md` (execution sequencing) is
written after Design, as Build preparation.

## Design — spec, ADRs, tickets, and the approval gate

1. **spec.md**: the spec for issue `#n` lives at
   `intent/<n>-<slug>/spec.md`, a sibling of the intent (ADR 0001), its
   header linking back to the issue and intent; the issue links to it by
   path. Never copy the spec into the issue body. Required sections:
   problem statement, requirements (user stories), design concerns
   (modules/interfaces/seams), constraints (system/UX/security), testing
   decisions, out of scope, open questions. Template:
   `intent/TEMPLATE-spec.md`.
2. **ADRs**: a decision that is hard to reverse, surprising without context,
   or a real trade-off gets a one-paragraph record in `docs/adr/NNNN-slug.md`,
   committed and pushed immediately. Tech-stack preferences and conventions
   live here too — shared brain for every agent. Existing ADRs constrain new
   design: contradictions are surfaced or superseded, never silently
   overridden.
3. **Tickets**: break the spec into vertical-slice sub-issues of the design
   issue (ADR 0002), each with explicit blocking edges via native `blocked_by`
   dependencies where available, else a `Blocked by: #n` body line
   (mechanics: `docs/agents/issue-tracker.md`), runnable acceptance criteria,
   and spec/ADR references. Triage labels move issues
   through their state machine; issues end as **`ready-for-agent`** (blockers
   resolved + acceptance criteria defined). The label is a
   contract: no label, no work. The linked-issue graph IS the design.
4. **Approval gate**: ordinary design is approved conversationally in the
   issue thread; high-risk work (security, data loss, irreversible
   migrations, public contracts) needs explicit human sign-off in the issue
   plus an ADR.
5. **Build read order**: issue → spec → ADRs → `CONTEXT.md` → code.
   Greenfield and brownfield run the same workflow; only the seed differs
   (brief/PRD vs diagnosis/retro).

## Build — agents execute against the tracker

One ticket per agent session, worked in the Build read order (issue → spec →
ADRs → `CONTEXT.md` → code). Workers cite relevant ADRs, respect blocking
edges, keep diffs lean (stdlib first, test-first), and record new
hard-to-reverse decisions as ADRs — pushed immediately. Closing a ticket
requires pasted proof of its acceptance criteria. Orchestration is optional
and host-specific (single session works the frontier serially; parallel
builds use the host's mechanism — herdr panes under pi, headless workers
under Claude Code — under the host-neutral rules in the factory-orchestrator
skill: orchestrator never writes code, QC + adversarial review before
blessing, HANDOFF ping, two-failure halt). Workers end with a HANDOFF ping
to the orchestrator when orchestrated: what landed, ADRs written, followups.

## Test — one command, fail-first, protected checks

One command is the gate: `tests/validate.sh [<range>]` prints one
`ok:`/`FAIL:` line per check, then `N ok, M failed`; non-zero exit means
"not healthy." Closing a ticket pastes that run (full output + exit code,
with the ticket's range) — for a bug/defect fix, plus the fail-first pair
(red on the bad version, then green) — never an assertion; a close missing
any of the run, the acceptance output, or the pair (for fixes) is reopened. Fail-first: a bug fix pastes
the check red on the bad version, then green; a new static check is admitted
only with a witness (historic sha or one-line mutation), and
`tests/validate.sh --witness` replays them all. Protection rule: a diff that
removes, narrows, or reorders a check away from what it guards — or removes
or narrows content a negative check guards, in `tests/` or anywhere — is
rejected unless it cites the issue retiring the rule; the fixer of a
checking surface never loosens the check in the same diff. Tests check
artifacts (deterministic, offline); behavioural findings are evals and stay
in the eval ledger. The check list lives in the `## Commands` block of
`AGENTS.md`, its token set verified by the suite itself (prose and grouping
unverified). The orchestrator still QCs against the intent plus an
adversarial pass.

## Deploy — gated

Standard pipeline; branch protection on main is the gate.

## Maintain — the intake point

Retro findings, production learnings, and transcripts get structured into
PRDs/intents and fed back through the full cycle. Feedback deposits into git
(ADRs, workflow doc, new issues) rather than dying — the loop gets shorter and
more reliable each revolution.

## Humans above the loop

- **Instigating**: the intent — the one artifact only humans approve. Issues
  first, one request per issue; intents live at
  `intent/<issue-number>-<slug>/intent.md`, aligned with `SYSTEM-INTENT.md`.
- **Directing**: the tracker arbitrates — labels + blocking edges decide flow.
- **Governing**: review, scope approval, proof requirements at every seam.

Non-negotiables: GitHub Issues is the tracker (no side TODO files). Blocking
edges are explicit (native dependencies or declared fallback). `ready-for-agent` is a contract. ADRs are pushed
immediately. Closing work requires pasted proof. Artifacts over conversation.

Full detail: `docs/engineering-workflow.md` in the repo.