# Plan: Deploy-stage tickets (from spec — approved)

## Files that change

- T1 (policy): `REVIEW.md` (new, repo root). Nothing else.
- T2 (docs + check): `docs/engineering-workflow.md` (new `## Deploy` section
  after `## Test`), `plugin/skills/engineering-workflow/SKILL.md` (rewrite
  `## Deploy — gated`), `README.md` (rewrite the `Deploy ──►` line),
  `tests/validate.sh` (stage-parity alternations gain `Deploy`, `444`→`555`,
  three new mutation witness rows), `CONTEXT.md` (new terms **merge gate**,
  **preview proof**).

T2 lands doc + SKILL + README + check + witnesses in **one sha** (sync
execution rule; Test §4 — the check is updated by the diff it measures,
cited to #12).

## Order of work

T1 first — the Deploy section references `REVIEW.md` by path, so the path
must resolve at T2's landing sha. **T2 blocked_by T1.**

## Pre-answered ambiguities (carried into worker prompts)

T1:
- Exactly four `##` sections as pinned in the spec: Passes, Severity,
  Skip-list, The loop. No nit cap (cut at spec time — out of intake scope).
- Skip-list names: everything `tests/validate.sh` enforces, `.factory/`,
  generated files (none today).
- T1's own close runs the loop it defines: orchestrator runs the
  `code-review` skill + adversary on its diff; verdict pasted at close.

T2:
- Branch protection stated as absent: `gh api` → 403 on this private
  free-plan repo (verified); human checkoff is the only enforcement until
  #1. The contract must not imply a server gate exists.
- Autonomy table per spec: flagged risk = any suite-checked surface +
  `docs/agents/` + security/trust boundaries + irreversible ops → human
  checkoff; everything else lands on a green gate.
- No `ADR <number>` references to unwritten ADRs anywhere `adr-refs` greps.
- stage-parity witnesses: keep `1b41a31` FAIL (now 3/5/5, reason string
  changes); add three HEAD-worktree mutation rows —
  `grep -v '^## Deploy'` on the doc, same on the SKILL,
  `grep -v '^Deploy '` on README — each → FAIL.
- AGENTS.md untouched: no new check names, `agents-commands` unaffected.
- Section length: contract-tight, comparable to the Test section.

## Risks

- T2 is the sync+check surface — the risky half. If the worker splits the
  landing into multiple commits, `sync-rule` fails on the range; the worker
  prompt must say "one commit."
- The mutation rows exercise HEAD — they are fail-first only because the
  same sha lands the Deploy lines; `--witness` on the landing sha is the
  proof, pasted at close.
- Vocabulary drift: CONTEXT.md terms (gate, check, witness) used exactly;
  new terms added in the same commit as the section.

## Dispatch

- Model: auto-routed per operator instruction (no pin); pin a smarter model
  per ticket only if QC shows the ticket warrants it. Fable stays unused.
- One ticket per worker session, fresh pane; `ORCH_PANE_ID=w1:p3E`.
- QC per ticket: orchestrator reproduces acceptance criteria by hand +
  adversary pass on the diff. Two consecutive QC failures → halt.

## Proof

- T1: `grep -n '^## ' REVIEW.md` showing the four sections + review and
  adversary verdicts on its own diff + `tests/validate.sh origin/main..HEAD`
  pasted at close.
- T2: `tests/validate.sh origin/main..HEAD` exit 0 (sync-rule + stage-parity
  green on the landing sha) + `tests/validate.sh --witness` transcript
  (stage-parity rows: 1b41a31 FAIL, three Deploy-removal mutations FAIL) +
  `git show --stat` of the one sha listing all touched files.
