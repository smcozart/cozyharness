# Intent: A codified Design-stage contract for the Harness

**Issue:** #3 · **Status:** approved · **Type:** system-change

## Problem

Plan (issue #2) defined the intent-first contract, but Design is
under-specified: an agent reaching the end of Plan cannot tell what a spec.md
contains, where it lives, when a design decision deserves an ADR, how a spec
breaks into ticket issues, or what approval moves work toward
`ready-for-agent`. Each gap is currently answered from chat memory, which
violates the system's own proof-over-claim rule.

## Desired outcome

The Design stage is codified in `docs/engineering-workflow.md` (synced to the
plugin skill and README per the sync rule), with a runnable spec template, a
seeded CONTEXT.md glossary, ADRs for the decisions above the bar, and a
documented approval gate — such that a fresh agent can produce a conforming
spec and ticket set from the repo alone.

## Scope

- spec.md contract: location, required sections, link-back to issue + intent,
  template with worked example
- CONTEXT.md glossary of Harness vocabulary
- ADR participation in Design and the ADR bar
- to-tickets structure: vertical-slice child issues, blocking edges,
  acceptance criteria, parent/child relationship
- Design approval gate (conversational vs high-risk) and its relation to
  `ready-for-agent`
- Build-consumer read order; greenfield vs brownfield as one workflow

## Non-goals

- Implementing code or hooks (belongs to issue #1 and Build-stage work)
- Changing the Plan-stage contract (closed in #2)
- Build-phase worker prompt templates (build-specific, live in `.factory/`)
- Creating child ticket issues for this work — the contract faces land in the
  parent issue

## Acceptance criteria

- DESIGN section present in `docs/engineering-workflow.md`, synced to
  `plugin/skills/engineering-workflow/SKILL.md` and `README.md` in the same
  commit
- `intent/TEMPLATE-spec.md` exists with template + worked example
- `CONTEXT.md` exists at repo root
- ADRs landed for spec location and ticket structure
- Issue #3 closes with pasted `git diff --stat` proof

## System-intent alignment

Serves SYSTEM-INTENT purposes 2 (tracker as system of record), 4 (ADRs for
hard-to-reverse decisions), and 5 (process lives in the repo, tool-portable):
it makes the Design stage reproducible by any agent harness from repo
artifacts alone.
