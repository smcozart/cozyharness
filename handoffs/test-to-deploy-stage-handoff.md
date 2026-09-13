# Handoff: Deploy Stage — Orchestrator Session

**Date:** 2026-09-12 · **From:** Build-orchestrator session (pi, herdr pane `w1:p2Y`)
**To:** Deploy-stage orchestrator · **Repo:** https://github.com/smcozart/cozyharness (branch `main`, clean)

## Primary external reference (reread the Deploy + Test plays)

Anthropic AI-Native SDLC playbook:
https://claude.com/blog/the-ai-native-sdlc-playbook
**Deploy play:** PR review loop (REVIEW.md policy), approval hooks, sandboxed
CI/CD, autonomy tiers. This repo's Deploy codification is text-level; Merge+
Test canon is already codified.

## Status of the six stages

- **Plan #2 · Design #3 · Build #4 · Test #9 — CLOSED with proof.**
- **Deploy #12 — OPEN (parent created; intent + spec + tickets are your first
  tasks, gated by operator at each step).**
- Maintain — prose-level; not started.

## Your role

Deploy-stage orchestrator. You manage worker sessions; you do not write
implementation code yourself. Same gates as Test cycle:
operating manual is `.agents/skills/factory-orchestrator/SKILL.md` (read first,
in full); model pin for workers + adversary = `moonshotai/kimi-k3` (Fable was
tried and cut for cost; Opus availability recorded in models-store).

## Domain docs to read in order

AGENTS.md → docs/engineering-workflow.md → SYSTEM-INTENT.md → CONTEXT.md →
docs/adr/ → docs/agents/*. Also `.factory/design.md` (orchestrator-local;
regenerate it as Deploy-specific — untracked by design).

## What #12's agreed scope says (operator-approved at intake)

1. PR review loop as a contract (policy + reviewers give/receive reviews).
2. Merge gate definition — review findings resolved, `tests/validate.sh` run,
   adversary verdict, human checkoff for flagged risk, and for UI tickets a
   preview proof (screenshot / recording / standing link) pasted at close.
3. Branch-protection verification (thin check; extend-friendly to #1).
4. Autonomy boundaries (human gate vs self-merge rules, docs-first).

Non-goals: hooks/#1, docker/sandbox, visualization runtime for this repo.

## Hard constraints from prior stages (don't relitigate)

- Issues #2/#3/#4/#9 closed; don't reopen their contracts.
- Sync rule: any `docs/engineering-workflow.md` change hits `plugin/skills/`
  + `README.md` in the same commit (the sync-rule check verifies touches).
- Triage vocabulary = 5 labels only.
- Workflow doc "closes mean more than proof": close a ticket with run +
  acceptance output + (for bug fixes) the fail-first pair. This norm arrived
  at #11.

## The Test gate you must run per ticket

`bash tests/validate.sh [<range>]` — closing a ticket pastes its run. 14
checks + witness mode (`--witness` = fail-first replay). The suite lives at
`tests/validate.sh`. Guard its assertions.

## How the prior stage arrived (so your plan.md sequence is smooth)

Design was draft→fix→fix→fix; approval gate hit APPROVE-WITH-NITS then a
final one-clause residual fold. Tickets split (#10 script, #11 docs). Kansas
Findings were adversary-driven across Fable/kimi-k3. Anything missing should
be told to operator, not improvised around.

## Ops context (relevant Learnings)

- Worker prompt template lives in previous orchestrator `.factory/design.md`
  (see this pane's file, or rebuild per skill).
- Panes: `herdr tab create` → `herdr agent start <name> --kind pi
  --pane <id> -- --model moonshotai/kimi-k3` → `herdr agent prompt`.
- Polling: `herdr agent list`; read on stall: `herdr agent read <pane>`.
- Handoff pings come back to this session's pane id; set ORCH_PANE_ID in every
  worker prompt (this session's: `w1:p2Y` — yours will differ).
- QC failures: reopen issue, paste findings, steer worker via resume directi-
  ve. Two consecutive QC failures → halt and revisit with operator.
