# Handoff: Design Stage

## Purpose of next session

Continue formalizing the AI-native SDLC harness by moving from the completed Plan stage into the Design stage. Keep Plan, Design, and Build tightly connected. Do not re-litigate or undo the completed Plan-stage contract unless new evidence requires it.

## Primary source

Anthropic AI-Native SDLC playbook:
https://claude.com/blog/the-ai-native-sdlc-playbook

Read it fully before proceeding. It defines the six-stage loop:

```text
Plan → Design → Build → Test → Deploy → Maintain → back to Plan
```

Key playbook artifact chain:

```text
intent.md → spec.md → plan.md → diff + tests → review findings
```

Anthropic's maturity model begins with hand-invoked stages and evolves toward accepted artifacts firing the next gate. Humans remain above the loop: instigating, directing, and governing.

## Repositories and checkpoints

System repository:

```text
https://github.com/smcozart/cozyharness
```

This is the harness product. `cozycode_pi` is the private project/factory repo that originally dogfooded it; do not confuse the two.

Plan-stage baseline and completion tags on `cozyharness`:

```text
pre-plan-stage-commit   237836f
post-plan-stage-commit  ab31857
```

Plan-stage issue:

```text
https://github.com/smcozart/cozyharness/issues/2
```

Hooks enforcement remains separately tracked in issue #1. Do not implement hooks during Design-stage work unless explicitly requested.

## What was completed in Plan

The Plan stage now defines:

1. Issue-first intake for meaningful work, in both greenfield and brownfield systems.
2. One meaningful request per GitHub issue.
3. Multiple requests in one conversation are split into separate issues.
4. Each issue gets a work-item intent at:
   `intent/<issue-number>-<slug>/intent.md`
5. `SYSTEM-INTENT.md` explains the enduring purpose of the harness.
6. Work-item intents explain their relationship to system intent.
7. Normal work uses conversational approval recorded in the issue thread.
8. High-risk work requires explicit human review and an ADR where appropriate.
9. Existing triage labels remain unchanged:
   `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`.
10. `ready-for-agent` remains the dispatch contract: blockers resolved and acceptance criteria defined.
11. `plan.md` belongs to Build preparation after Design, not to the Plan stage.
12. Prototype work is intentionally deferred.

## Important artifact responsibilities

```text
SYSTEM-INTENT.md
  = why the system exists

intent/<issue-number>-<slug>/intent.md
  = why this specific work item exists

spec.md
  = what should be built

plan.md
  = how the implementation will change the code

GitHub issue
  = operational state, ownership, dependencies, discussion, and proof links

ADR
  = why a durable technical or process decision was made

PR + tests
  = implementation and verification evidence
```

## Files to read first

In `cozyharness`:

- `SYSTEM-INTENT.md`
- `intent/TEMPLATE.md`
- `docs/engineering-workflow.md`
- `docs/agents/issue-tracker.md`
- `docs/agents/triage-labels.md`
- `docs/agents/domain.md`
- `README.md`
- `CONTRIBUTING.md`
- `plugin/skills/engineering-workflow/SKILL.md`
- `plugin/skills/factory-orchestrator/SKILL.md`

## Design-stage questions to answer

Work collaboratively with the operator. Do not make broad implementation changes until the Design-stage contract is agreed.

1. What exactly should Design produce from an accepted work-item intent?
   - `spec.md` structure and location
   - requirements and design concerns
   - system/UX/security constraints
   - links back to issue and intent

2. How should ADRs participate in Design?
   - when an intent requires an architecture or technology decision
   - how ADRs link to the issue, intent, and spec
   - how existing ADRs constrain new design

3. How should `/to-tickets` structure GitHub issues from the spec?
   - vertical tracer-bullet slices
   - dependency/blocking edges
   - acceptance criteria
   - category/state labels
   - relationship between the parent design issue and child implementation issues

4. What is the exact Design approval gate?
   - conversational approval for ordinary design
   - explicit human review for high-risk or system-level decisions
   - what transitions an issue toward `ready-for-agent`

5. How should a fresh Build agent consume Design artifacts?
   - issue
   - system intent
   - work-item intent
   - relevant CONTEXT and ADRs
   - spec
   - then repository/code inspection

6. How do greenfield and brownfield Design differ without creating two workflows?

7. How does the factory/orchestrator join to GitHub issue numbers, intent paths, specs, branches, PRs, and proof? Do not allow a generic factory run ID or deliverable string to replace the GitHub issue join key.

8. Which parts should be explicit skills, which should be repo artifacts, and which should eventually become hooks or deterministic gates?

## Adversarial findings to keep in mind

Prior reviews identified these risks:

- A factory run must carry an explicit GitHub `issue_number`; otherwise runs and issues cannot be joined.
- Per-issue intent paths must remain isolated for concurrent brownfield work.
- System-intent alignment must not become decorative boilerplate.
- Fresh-agent read order and source-of-truth precedence need to be explicit.
- The existing label lifecycle should not be expanded casually; it is currently smooth.
- Small work should be allowed to discharge stages cheaply rather than accumulating ceremony.
- `wontfix` should remain closed historical knowledge, not active queue noise.
- Hooks are a future deterministic enforcement layer behind advisory skills; issue #1 tracks this separately.

## Orchestration expectations

Use the factory-orchestrator methodology for substantial Design work:

- one issue per worker
- fresh worker session
- orchestrator does not write implementation code
- worker reads the design and relevant artifacts first
- worker ends with a `HANDOFF:` line
- orchestrator runs acceptance checks independently
- run adversarial review before blessing
- two consecutive QC failures halt further dispatch
- push ADRs and durable artifacts

For this Design stage, a planning/design worker and an independent reviewer are more useful than parallel implementation workers. Keep the operator involved at the approval gates.

## Suggested skills for the next session

- `domain-modeling` — ADR and shared vocabulary decisions
- `to-spec` — convert accepted intent into a design/spec artifact
- `to-tickets` — break the design into vertical GitHub issues with blocking edges
- `triage` — validate issue state and ready-for-agent requirements
- `grilling` or `grill-with-docs` — stress-test design decisions
- `codebase-design` — deepen the interface and architecture where needed
- `factory-orchestrator` — coordinate workers and QC
- `code-review` and the `adversary` subagent — review any resulting diff

## Session opening instruction

Start by stating what Design must produce, then read the Anthropic playbook and the listed repository artifacts. Present the proposed Design contract to the operator before changing files. The goal is to finalize the Design stage, create a durable checkpoint, and only then proceed to Build.
