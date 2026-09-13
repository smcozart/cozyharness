# Handoff: Maintain Stage — Orchestrator Session

**Date:** 2026-09-12 · **From:** Deploy-stage orchestrator (pi, herdr pane `w1:p3E`)
**To:** Maintain-stage orchestrator · **Repo:** https://github.com/smcozart/cozyharness (branch `main`, clean at `13e8970`)

## Primary external reference (read the Maintain play first)

Anthropic AI-Native SDLC playbook: https://claude.com/blog/the-ai-native-sdlc-playbook
**Maintain play (Stage 6):** closing the loop — production incidents become permanent evals, drift detection with rule bands, rollback rehearsed, retros/PRDs/transcripts feed the next cycle through Plan. Fetch it via curl (it renders as HTML; strip tags, the Maintain play follows "06 Maintain") or ask the operator for a saved copy.

## Status of the six stages

- **Plan #2 · Design #3 · Build #4 · Test #9 · Deploy #12 — CLOSED with proof.**
- **Maintain — the last stage, prose-level.** No parent issue exists yet. Unlike
  Deploy (whose parent #12 was created at intake with operator-approved scope),
  **your first work is issue-first intake**: draft the Maintain parent issue +
  `intent/<n>-maintain-stage/intent.md` from the playbook's Maintain play and
  the workflow doc's existing one-liner ("Maintain — the intake point"), present
  at Gate 1. Do not pre-decide scope; the operator holds all gates.

## Your role

Maintain-stage orchestrator. You manage worker sessions; you do not write
implementation code yourself. Operating manual: `.agents/skills/factory-orchestrator/SKILL.md`
(read first, in full). Per-ticket loop, QC + adversary, HANDOFF pings, halt rule:
all in the skill.

## Read list (in this order, in full)

AGENTS.md → docs/engineering-workflow.md (now carries all five codified stages) →
SYSTEM-INTENT.md → CONTEXT.md → docs/adr/ → docs/agents/* → **REVIEW.md** (new —
the review policy your closes and your workers' closes run under) → issues #12,
#13, #14 closed (the Deploy pattern: intent → spec → plan → 2 tickets → QC
rounds), #1 and #8 open (tracking comments from Deploy explain what waits on
them) → `.factory/design.md` (Deploy-era; regenerate it as Maintain-specific —
untracked by design).

## Hard constraints (don't relitigate)

- Issues #2/#3/#4/#9/#12 closed — don't reopen their contracts.
- Sync rule: any `docs/engineering-workflow.md` change hits
  `plugin/skills/engineering-workflow/SKILL.md` + `README.md` **in the same
  commit** (per-commit, not per-range — this bit a worker in Deploy QC round 2).
- Triage vocabulary = 5 labels only. `ready-for-agent` = blockers resolved +
  acceptance criteria defined.
- Test gate per close: `tests/validate.sh [<range>]` pasted + fail-first pairs
  for fixes; witnesses runnable via `--witness`; protection rule guards checks.
- **Findings tag by risk class** (Bugs/Security/Compliance) regardless of
  surfacing pass; carried notes are tracker-owned by a non-author, re-verified
  at the operator checkpoint (REVIEW.md; a spec-pin deviation on #12 awaits
  operator ratification — carried items listed in #12's close comment).
- Model policy (operator, supersedes the old kimi-k3 pin): **auto-routed, no
  pin**; pin a smarter model only if QC shows the ticket warrants it; Fable
  stays unused.

## The Maintain-stage mechanic you must verify early (Deploy-pattern)

`check_stage_parity` in `tests/validate.sh` currently expects **555** across the
synced trio, with 8 witness rows (baseline ok + historic sha + 3 removal + 3
rename mutations — every leg has fail-first; a green-baseline row anchors the
mode). SKILL.md already has `## Maintain — the intake point` and README already
has a `Maintain ─►` line; the canonical doc has **no `## Maintain` section**.
Codifying Maintain means: alternations gain `Maintain`, `555`→`666`, witness
rows updated/re-recorded (same one-sha landing, same per-leg witness pattern,
same Test §4 protection-rule citation). Verify all counts yourself before
pinning anything in the spec — the Deploy spec pinned verbatim patterns and
re-verified witnesses by hand, and that rigor held up under 7 QC rounds.

## QC lessons from Deploy (fold into your loop)

1. **Always run the suite three ways at close QC: bare (HEAD~1..HEAD — catches
   per-commit sync violations), with the ticket's range, and `--witness`.** A
   range run alone masked a sync violation once.
2. Run the `adversary` subagent on every diff before blessing; it caught 6 of
   the stage's 10 real defects (wrong witness counts, name-blind check,
   vacuous-witness baseline, self-ownable carries, taxonomy mismatches).
3. Reject findings with written rationale on the issue; fold findings with
   numbered directives; **amend, don't stack** on solo unmerged branches
   (force-with-lease).
4. Rejected-as-over-engineered on the record: guarding full heading prose in
   stage-parity (breaks on benign retitles); preview-proof example artifacts;
   eye-review compensating for hypothetical under-covering checks.

## Ops context

- Worker panes: `herdr tab create` → `herdr agent start <name> --kind pi
  --pane <id>` (no --model flag = auto) → `herdr agent prompt <pane>
  "$(cat promptfile)"` (write prompt files to /tmp; heredocs in
  command substitution break on parens).
- Poll `herdr agent list`; read a screen on stall with `herdr agent read`;
  workers end with `HANDOFF:` pings to YOUR pane id — set ORCH_PANE_ID in every
  worker prompt (discover yours via `herdr agent list`; you're the focused
  maintain-orchestrator).
- Worker prompt template: `.factory/design.md` (regenerate as Maintain-specific)
  and the skill §Worker prompt template.
- Two consecutive QC failures on any workers → halt the chain, revisit with the
  operator. Orchestrator never writes code; workers bounce missing specs, never
  improvise.

## Definition of done (stage-level)

Maintain codified with the same rigor as #2/#3/#4/#9/#12: a `## Maintain`
section in the workflow doc (synced per the rule), the suite's stage-parity
guarding 6 stages with per-leg witnesses, CONTEXT.md vocabulary updated, every
child ticket closed with pasted proof under the Deploy gate (validate runs,
review + adversary verdicts, branch-protection paste or n/a, human checkoff for
flagged risk), parent issue closed citing all children. ADRs only if a real
trade-off emerges — next number is 0003.
