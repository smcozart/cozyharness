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
3. Onboarding order for a fresh session on an existing repo: read
   `AGENTS.md` → `docs/engineering-workflow.md` → `gh issue list --label
   ready-for-agent`. That sequence reconstructs full context from the repo
   alone — never from chat history.

## Plan — the intent & the why

Produce an **intent** (file or epic-issue body): problem, desired **outcome**
(not a task list), scope, non-goals. Bug fixes seed it from the diagnosis;
features from the brief; PRDs from transcripts. The intent is the lighthouse —
everything downstream is graded against it. Human approves scope before
anything spins. No intent, no work.

## Design — structure the work, record the decisions

1. **ADRs**: decisions that are hard to reverse, surprising without context, or
   real trade-offs get a one-paragraph record in `docs/adr/NNNN-slug.md`,
   committed and pushed immediately. Tech-stack preferences and conventions
   live here too — shared brain for every agent.
2. **Tickets**: break the intent into vertical-slice GitHub issues, blocking
   edges declared in the body. Triage labels move issues through their state
   machine; issues end as **`ready-for-agent`** (blockers resolved + acceptance
   criteria defined). The label is a contract: no label, no work. The
   linked-issue graph IS the design.

## Build — agents execute against the tracker

One ticket per agent session. Workers cite relevant ADRs, respect blocking
edges, keep diffs lean (stdlib first, test-first), and record new
hard-to-reverse decisions as ADRs — pushed immediately. On large builds,
workers run under an orchestrator (which never writes code itself; herdr for
parallel panes — see the factory-orchestrator skill). Workers end with a
HANDOFF ping to the orchestrator: what landed, ADRs written, followups.

## Test — proof over claim

Run the test suite. Closing work requires pasting the verification commands
and their output into the issue — never an assertion. Failures reopen the
issue with the failing command. The orchestrator QCs against the intent: did
we veer off course? Plus an adversarial pass (assume the diff is wrong).

## Deploy — gated

Standard pipeline; branch protection on main is the gate.

## Maintain — the intake point

Retro findings, production learnings, and transcripts get structured into
PRDs/intents and fed back through the full cycle. Feedback deposits into git
(ADRs, workflow doc, new issues) rather than dying — the loop gets shorter and
more reliable each revolution.

## Humans above the loop

- **Instigating**: the intent — the one artifact only humans author.
- **Directing**: the tracker arbitrates — labels + blocking edges decide flow.
- **Governing**: review, scope approval, proof requirements at every seam.

Non-negotiables: GitHub Issues is the tracker (no side TODO files). Blocking
edges live in issue bodies. `ready-for-agent` is a contract. ADRs are pushed
immediately. Closing work requires pasted proof. Artifacts over conversation.

Full detail: `docs/engineering-workflow.md` in the repo.