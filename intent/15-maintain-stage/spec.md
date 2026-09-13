# Spec: Maintain stage contract — intake point, eval-on-incident, consumer obligations

**Issue:** #15 · **Intent:** `intent/15-maintain-stage/intent.md` ·
**Status:** approved · **ADRs:** none (every decision below is visible in the
artifacts it lands; nothing here meets the ADR bar)

## Problem statement

The workflow doc's six-phase loop ends in an uncodified stage: `## Maintain`
exists nowhere in the canonical doc, and the synced SKILL/README renderings
are a thin paragraph and a pipeline line. A fresh agent cannot answer the
questions the stage exists to answer — where do retro findings, incident
learnings, and transcripts re-enter the pipeline, where do findings with no
textual footprint live, and what do consumers of the process owe around drift
detection and rollback.

## Requirements

1. As a fresh agent picking up retro/incident learnings, I want a `## Maintain`
   section in the canonical workflow doc that defines the **intake point**,
   so that field signals become issues and work-item intents through Plan
   instead of dying in chat.
2. As a Test-stage reader, I want the **eval-on-incident rule** written as
   contract — every fixed incident class becomes text in the eval ledger
   (#8) — so that incident classes accumulate protection without waiting on
   the frozen harness (#1).
3. As a consumer repo adopting the Harness, I want drift detection and
   rollback written as obligations I owe, so that the contract tells me what
   to provide even though this repo has no production runtime (same shape as
   preview proof).
4. As the suite, I want `stage-parity` to expect 6 stages (666) so that the
   synced trio cannot silently drop or thin the Maintain contract.
5. As a reader of CONTEXT.md, I want **intake point** and **eval ledger**
   defined, so that the new section's vocabulary is pinned before any worker
   writes it.
6. As the operator, I want every child ticket closed under the Deploy merge
   gate, so that Maintain lands with the same proof rigor as Deploy did.

## Design concerns

- **One landing, one sha.** The canonical `## Maintain` section, the
  compressed SKILL paragraph, the compressed README line, the two CONTEXT.md
  definitions, and the `stage-parity` 666 update land in a single commit —
  the sync rule forces the trio together, and Test §4 forbids loosening
  (here: leaving stale) the check that measures the surface in the same diff.
- **Verbatim canonical section** (pinned; the worker reproduces this text
  under `## Maintain` in `docs/engineering-workflow.md`, positioned after
  the Deploy section and before `## Stage-by-stage map`):

  > ## Maintain — closing the loop
  >
  > Maintain is the intake point: retro findings, incident-class learnings,
  > and session transcripts get structured into issues and work-item intents
  > and re-enter through Plan — findings become intents humans approve, never
  > autonomous fixes. Feedback deposits into git (issues, ADRs, workflow
  > doc, CONTEXT.md), never dies in chat; the loop gets shorter and more
  > reliable each revolution.
  >
  > **Eval-on-incident:** every fixed incident class becomes eval material
  > in the eval ledger (#8) — the Test §5 boundary; the ledger is a
  > document, and the only permitted writes are text (no runner, scanner, or
  > automation lands here until #1 unfreezes). Dismissed findings stay on
  > record with a reason.
  >
  > **Consumer obligations (this repo has no production runtime — contract
  > text only, same shape as preview proof):** a consumer of the Harness
  > owes a drift-detection rule set for the metrics it runs the loop on
  > (version-controlled config; detection deterministic, no model involved),
  > and a rehearsed rollback path for what the loop may trigger at its
  > highest tier. Both arrive as findings through the intake point, and
  > fixed incident classes become eval material per the rule above.
  >
  > Automation of this stage — triggers, hooks, monitoring bands, rollback
  > tooling — waits on #1.

- **Verbatim CONTEXT.md definitions** (pinned; appended to `## Language` in
  the same sha):

  > **intake point**:
  > The Maintain seam where retro findings, incident-class learnings, and
  > session transcripts are structured into issues and work-item intents and
  > re-enter through Plan. Findings become intents humans approve — never
  > autonomous fixes.
  > _Avoid_: feedback loop (vague), incident process (reactive connotation)

  > **eval ledger**:
  > The corpus of prompt+check pairs for behaviors with no textual footprint
  > for the suite to grep, tracked in issue #8. The ledger is a document;
  > writes are text only until the eval harness exists (#1). Fixed incident
  > classes land here per the Maintain section's eval-on-incident rule.
  > _Avoid_: eval suite (nothing runs yet), regression tests (those are
  > checks)

- **SKILL compression** (rewrites the existing `## Maintain — the intake
  point` paragraph; must carry all three bullets — intake point,
  eval-on-incident, consumer obligations — in ~the current paragraph's
  length; reviewer-verified by eye against the canonical text above, since
  the suite checks the file-triple, not prose parity).

- **README compression** (rewrites the `Maintain ─►` line to carry the same
  three bullets in pipeline-line form, e.g. `Maintain ─► intake: retros/
  incidents feed back through Plan; fixed incident classes → eval ledger
  (#8)`).

- **stage-parity change** (in `tests/validate.sh`, same sha): widen all six
  alternation-bearing greps — three count-pass, three distinct-pass — to
  `(Plan|Design|Build|Test|Deploy|Maintain)`, both count assertions `555` → `666`, and the two `why` strings "5 stage headings" /
  "5 distinct stage names" → 6. Witness rows re-recorded, same structure
  (verified against the current script):
  - historic sha `1b41a31` stays — it reads doc=3 / SKILL=6 / README=6 under
    the widened alternation, `366 ≠ 666`, still FAIL (fail-first preserved);
  - baseline ok row stays;
  - 3 removal mutations re-pointed from `## Deploy` to `## Maintain` (one
    per leg: canonical doc, SKILL, README);
  - 3 rename mutations re-pointed from Deploy→Test to Maintain→Test (one per
    leg, README row renames the `Maintain ─►` line).
  The landing cites #15 for the Test §4 protection rule: this diff touches
  `tests/validate.sh` and is the issue that extends the rule (widening, not
  loosening — the check gets stricter).

- **Ticket cut: two children.** T1 = the one-sha Maintain landing (merge-path:
  touches `tests/validate.sh` + the synced trio → branch-protection proof
  owed, human checkoff owed). T2 = tracker wiring — post the extend-friendly
  dependency comments on #1 and #8 naming the new Maintain contracts as
  their unblock surface (mirrors the Deploy pattern; no repo files). Parent
  #15 closes citing both (ADR 0002). T2's own close owes the same
  per-child gate evidence as T1: pasted acceptance-criteria output, a
  pasted `tests/validate.sh [<range>]` run (bare + range + `--witness`),
  review and adversary verdicts, and "n/a — not a merge-path ticket" for
  the branch-protection item (T2 touches no repo files).

- **Seam under test:** the existing one — `tests/validate.sh` static +
  witness mode. No new check is added (Test §5; prose parity stays the #8
  gap).

## Constraints

### System

- Suite stays offline (Test §5): no online check joins `tests/validate.sh`.
- Sync rule per-commit, not per-range; the landing sha must pass a bare
  `tests/validate.sh HEAD~1..HEAD`.
- No new files join the synced trio; no new check names in the `CHECKS` list
  (the `agents-commands` check pins it).
- ADRs: none required; next number remains 0003 if the work surfaces a real
  trade-off.

### UX

- A fresh agent reading the canonical doc must reach the Maintain contract in
  the same read order as every other stage (one `##` section, no dangling
  references).
- The SKILL/README compressions must never contradict the canonical text —
  thinner, never different.

### Security

- None: docs + a check-widening change; no trust boundary crossed, no new
  tool surface, no secrets. The stage-parity change strictly strengthens the
  guard (6 > 5 stages pinned).

## Testing decisions

- External behavior, not implementation: the proof is the suite's own three
  runs at close — bare (per-commit sync violation catcher), ticket range,
  and `--witness` — pasted on the ticket, plus the stage-parity witness
  transcript showing every row's expected verdict.
- Prior art: the Deploy landing (#14) pinned verbatim patterns and
  re-verified witnesses by hand; replicate that rigor, including the
  adversary pass on the diff before blessing.
- No new tests beyond the widened `stage-parity`: every other check already
  guards the surfaces this diff touches (sync-rule, adr-refs, agents-
  commands are unaffected but re-run).

## Out of scope

- Hooks, CI, autonomous triggers, monitoring bands, rollback tooling — #1.
- Eval harness execution, prose-parity (sync-content-drift) check — #8.
- Playbook hosted products (scheduled scanning, channel on-call, Claude
  Tag) — consumer text only.
- `plan.md` — this stage is a single landing plus a tracker task; no
  execution sequencing beyond T1 → T2 exists to sequence.
- Reopening #2/#3/#4/#9/#12 contracts.

## Open questions

- None blocking. (Pre-folded from the Gate-1 adversarial review: parity AC is
  reviewer-verified by eye — mechanical prose-parity stays the #8 gap; the
  eval ledger is text-only writes.)