# Plan: Maintain-stage tickets (from spec — approved)

## Files that change

- T1 (docs + check): `docs/engineering-workflow.md` (new `## Maintain —
  closing the loop` section after `## Deploy`, verbatim per spec),
  `plugin/skills/engineering-workflow/SKILL.md` (rewrite the
  `## Maintain — the intake point` paragraph to the compressed contract),
  `README.md` (rewrite the `Maintain ─►` line per the spec-pinned example),
  `CONTEXT.md` (append **intake point** and **eval ledger**, verbatim per
  spec), `tests/validate.sh` (stage-parity: all six alternation-bearing
  greps gain `Maintain`, both count assertions `555`→`666`, both `why`
  strings 5→6, witness rows re-pointed Deploy→Maintain).

T1 lands all five surfaces in **one sha** (sync execution rule; Test §4 —
the check is updated by the diff it measures, cited to #15).

- T2 (tracker only): no repo files. Dependency comments on #1 and #8 naming
  the new Maintain contracts as their unblock surface (Deploy pattern).

## Order of work

T1 first — T2's comments must name contracts that exist at a pushed sha,
so the landing must be on main before T2 posts. **T2 blocked_by T1.**

## Pre-answered ambiguities (carried into worker prompts)

T1:
- One commit. If the worker splits the landing, `sync-rule` fails per-commit;
  the prompt says "one sha, `tests/validate.sh HEAD~1..HEAD` green on it".
- Verbatim means verbatim: the canonical section, both CONTEXT.md
  definitions, and the README `Maintain ─►` line are reproduced from the
  spec exactly (one dash in `─►`, matching the existing README line format).
- SKILL compression: rewrite the existing `## Maintain — the intake point`
  paragraph in place, keeping the heading line, carrying all three bullets
  (intake point, eval-on-incident, consumer obligations) at ~the current
  paragraph's length. Thinner than the canonical text, never different.
- stage-parity mechanics: widen all six greps (three count-pass, three
  distinct-pass); update both `why` strings to "6"; keep the `1b41a31`
  historic row (reads 3/6/6 under the widened alternation — still FAIL);
  baseline ok row stays; re-point the 3 removal mutations
  (`^## Maintain` on doc and SKILL, `^Maintain ` on README) and the 3
  rename mutations (Maintain→Test per leg, README renames `Maintain ─►`)
  — each verified to FAIL at 666 before pasting.
- The landing cites #15 for the Test §4 protection rule (widening, not
  loosening). No other check is touched; no new check names
  (`agents-commands` pins the list); AGENTS.md untouched.
- No ADR: nothing in this diff meets the ADR bar (spec §ADRs); do not write
  `ADR <number>` references to unwritten files (adr-refs greps them).
- T1 close is merge-path: branch-protection proof pasted (or recorded
  absence per Deploy §3) + human checkoff; bare + range + `--witness` runs
  all pasted; review + adversary verdicts on the diff.

T2:
- Comments on #1 and #8 are text only — they extend the existing
  Deploy-stage dependency comment pattern; no labels change, no issues
  reopen.
- T2's close owes the same per-child evidence: pasted acceptance-criteria
  output (the posted comment text + links), a pasted
  `tests/validate.sh origin/main..HEAD` run (suite must still be green;
  the diff is empty, so bare suffices per Test §1's range requirement —
  paste it anyway), adversary on the diff (verdict: no code diff, scope
  check only), and "n/a — not a merge-path ticket" for branch protection.

## Risks

- T1 is the sync+check surface — the risky half (all of it; there is no
  low-risk half this time). The one-sha constraint is the tripwire: a
  worker committing docs and check separately fails sync-rule on the bare
  run.
- The mutation rows exercise HEAD and are fail-first only because the same
  sha lands the Maintain lines; `--witness` on the landing sha is the
  proof, pasted at close.
- Vocabulary drift: CONTEXT.md terms used exactly as pinned; **intake
  point** and **eval ledger** added in the same sha as the section (intent
  AC).
- Partial widening: if the worker widens the count greps but not the
  distinct greps, the baseline witness row flips to FAIL — caught by the
  pasted `--witness` transcript, but costs a cycle; the prompt names all
  six greps.

## Dispatch

- Model: auto-routed per operator instruction (no pin); pin a smarter model
  per ticket only if QC shows the ticket warrants it. Fable stays unused.
- One ticket per worker session, fresh pane; `ORCH_PANE_ID` set at dispatch
  time from `herdr agent list`.
- QC per ticket: orchestrator reproduces acceptance criteria by hand +
  adversary pass on the diff. Two consecutive QC failures → halt.

## Proof

- T1: `git show --stat` of the one sha listing all five surfaces;
  `tests/validate.sh origin/main..HEAD` exit 0 (sync-rule + stage-parity
  green on the landing sha); `tests/validate.sh --witness` transcript
  (stage-parity rows: baseline ok, `1b41a31` FAIL at 3/6/6, three
  Maintain-removal mutations FAIL, three Maintain-rename mutations FAIL);
  branch-protection paste; review + adversary verdicts. All pasted at close.
- T2: posted comment texts + `tests/validate.sh origin/main..HEAD` exit 0
  pasted at close.