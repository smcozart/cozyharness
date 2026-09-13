# Handoff: Build Stage — Orchestrator Session

**Date:** 2026-09-12 · **From:** Design-stage orchestrator session (pi, herdr pane `w1:p2S`)
**To:** Build-stage orchestrator session · **Repo:** https://github.com/smcozart/cozyharness (branch `main`, clean, synced with origin)

## Your role

You are the **Build-stage orchestrator**. You manage worker sessions and do not
write implementation code yourself. Read and follow the factory-orchestrator
skill in full before dispatching anything:

- `/Users/seancozart/dev/cozyharness/.agents/skills/factory-orchestrator/SKILL.md`

Key contract reminders (the skill is authoritative):

- The live frontier is GitHub: `gh issue list --label ready-for-agent`. Nothing in a file outranks it.
- One ticket per worker session; fresh pane per ticket (`herdr tab create` → `herdr agent start <name> --kind pi --pane <id>` → `herdr agent prompt <pane> "$(cat promptfile)"`).
- Pre-answer the 2–3 ticket ambiguities in the worker prompt. Include your own pane id (`herdr agent list` shows the focused pane) so workers can send their final `HANDOFF:` ping back to you.
- Workers may run their own sub-agents; you (orchestrator) do QC yourself plus a mandatory adversarial review pass on every diff before blessing.
- Two consecutive QC failures anywhere → halt the chain and revisit with the operator.
- Workers end with a `HANDOFF:` ping to your pane; close spent panes.
- Pin a capable model for workers (Design used `moonshotai/kimi-k3` via `-- --model moonshotai/kimi-k3`; worked well).

## Where the project stands

The Harness (an AI-native SDLC process, packaged for Claude Code + pi) has
completed two of six stages by dogfooding its own process:

- **Plan — DONE (issue [#2](https://github.com/smcozart/cozyharness/issues/2), closed).**
  Issue-first intake; work-item intents at `intent/<n>-<slug>/intent.md`;
  `SYSTEM-INTENT.md`; `ready-for-agent` contract (blockers resolved + acceptance
  criteria defined — two conditions, never three).
- **Design — DONE (issue [#3](https://github.com/smcozart/cozyharness/issues/3), closed).**
  spec contract (ADR 0001: spec.md is `intent/<n>-<slug>/spec.md`, sibling of
  intent, referenced never copied); tickets as child issues with native
  `blocked_by` edges (ADR 0002); ADR bar = hard-to-reverse OR surprising OR
  trade-off, with `**Issue:** #n · **Status:** accepted` headers; approval gate
  before ticket-cut/labeling; Build read order; greenfield/brownfield as one
  workflow. Adversarially reviewed (initial BLOCK → remediation → APPROVE-WITH-NITS
  → residual MEDs fixed by orchestrator).
- **Build-prep codification — DONE (commits `57ff965`, `a6519a9`).** The
  canonical `## Build` section now exists in `docs/engineering-workflow.md`,
  host-neutral (herdr is a reference host, not a dependency — the process must
  also run under Claude Code/Codex; see SYSTEM-INTENT purpose 5).

## Your job: Build preparation, then Build

1. **Read first, in order:** `AGENTS.md` → `docs/engineering-workflow.md`
   (especially Plan, Design, and the new Build sections) → `SYSTEM-INTENT.md` →
   `CONTEXT.md` → `docs/adr/` → `docs/agents/*` → `.factory/design.md`
   (Design-stage orchestrator doc; regenerate a Build-specific version — see below).
2. **Create the Build work-item intent** (there isn't one yet): open a Build
   parent issue, then `intent/<n>-<slug>/intent.md` per `intent/TEMPLATE.md`,
   aligned with SYSTEM-INTENT.md. Get operator approval on it.
3. **Write `plan.md` as Build preparation** (per workflow doc: after Design,
   sequencing tickets + ADRs into execution order).
4. **Cut tickets with `/to-tickets`**: vertical tracer-bullet child issues of the
   Build parent, native `blocked_by` edges, runnable acceptance criteria per
   ticket, `ready-for-agent` when unblocked.
5. **Regenerate `.factory/design.md`** as the Build orchestrator doc (the current
   one is Design-stage-local and stale; it is untracked/build-local by design).
6. **Dispatch Build workers** per the skill, one `ready-for-agent` ticket each.
7. **Reverse-wiring check when Build lands:** every Build diff must tie back to
   Design (spec/ADR references) and Plan (intent alignment) — the operator wants
   this verified explicitly after Build work completes.

## Hard constraints / scope

- **Hooks are OUT of scope** — issue #1 tracks deterministic enforcement separately. Do not implement hooks.
- Issue #2/#3 are closed; do not reopen or re-litigate their contracts.
- The sync rule is non-negotiable: process changes update `docs/engineering-workflow.md`, `plugin/skills/engineering-workflow/SKILL.md`, and `README.md` in the same commit.
- Proof over claim: close tickets only with pasted verification output.
- Label vocabulary: exactly `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. Do not expand it.

## Primary external reference

Anthropic AI-Native SDLC playbook (defines the six-stage loop this whole system implements — reread the Build + Test plays before dispatching):
https://claude.com/blog/the-ai-native-sdlc-playbook

## Suggested skills

- `factory-orchestrator` — your operating manual (read first)
- `to-tickets`, `triage` — ticket cutting and queue grooming
- `implement`, `tdd` — what workers run per ticket
- `code-review` + an adversarial review pass — QC before blessing
- `handoff` — when your stage ends
- `grilling` — stress-test the plan.md with the operator before dispatch

## Operator preferences (learned this session)

- Lean into herdr orchestration: real sessions, not sub-agents from the orchestrator; sub-agents are for workers to use.
- Adversarial review with a smart model is mandatory QC (Design used kimi-k3; it caught 3 real HIGH defects).
- Keep the operator at approval gates: report between tickets; operator releases the next one.
- The process must stay host-neutral (pi today, Claude Code/Codex later).
