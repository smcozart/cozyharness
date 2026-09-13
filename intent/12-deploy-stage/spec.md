# Spec: Deploy-stage contract — review loop, merge gate, autonomy boundaries

**Issue:** #12 · **Intent:** `intent/12-deploy-stage/intent.md` ·
**Status:** approved · **ADRs:** follows 0001, 0002; none new expected (see Design concerns)

## Problem statement

Deploy is two thin sentences — `docs/engineering-workflow.md` has no Deploy
section; the plugin SKILL.md says "branch protection on main is the gate" and
README repeats it — while branch protection is not even enabled on this repo
(private, free plan: `gh api repos/{owner}/{repo}/branches/main/protection`
→ 403, verified 2026-09-12). The review habits that exist (code-review skill,
adversary pass, pasted validate.sh runs) are session conventions, not a
contract a fresh agent can read. This spec must (1) make the review loop a
contract with a policy artifact, (2) define what a unit of work owes before
merge, (3) define how branch protection is verified given it is absent today,
and (4) draw the human-gate vs self-merge line — all without touching the
offline suite's contract or the sync rule's scope.

## Requirements

1. As a reviewer, I want a review policy at a predictable path (`REVIEW.md`
   at repo root) naming the passes, the Important-vs-Nit severity rule, and
   the skip-list, so that every diff gets the identical set of passes.
2. As a worker, I want the review loop to run in both directions — reviews
   given on my diff and findings I must resolve — so that the PR thread /
   closing comment is the audit record.
3. As a closer, I want the merge gate enumerated — review findings resolved,
   `tests/validate.sh [<range>]` pasted (Test §1), adversary verdict, human
   checkoff for flagged-risk classes, preview proof for UI tickets — so that
   "ready to merge" is a checklist, not a judgment.
4. As an orchestrator, I want a documented manual branch-protection proof
   (`gh api …/branches/main/protection`, pasted), so that the gate's
   server-side enforcement is verified or its absence recorded — today:
   absence (403), making the human checkoff the only enforcement.
5. As the operator, I want autonomy boundaries written down — which change
   classes need a human gate and which an agent may land once the gate is
   green — so that governance is enforced as the agent acts, not after.
6. As a consumer-repo maintainer, I want the preview-proof obligation
   (screenshot / recording / standing link, pasted at close) written as a
   contract for UI tickets, so that visual changes carry proof even though
   this repo has no UI surface.
7. As a fresh agent, I want a `## Deploy` section in the workflow doc with
   all of the above, synced per the sync rule, so that Deploy has the same
   standing as Plan/Design/Build/Test.
8. As a maintainer, I want `stage-parity` to expect 5 stages with its
   witness updated in the same sha, so that the suite stays green and no
   check is loosened by the change it measures (Test §4).

## Design concerns

### REVIEW.md — the policy artifact (subordinate to the Deploy section)

Root `REVIEW.md`, referenced by path from the Deploy section. Not added to
the synced trio — the Deploy section names the gate; REVIEW.md is the
checklist it points at. Four `##` sections, pinned here (adapted from the
playbook's example):

- `## Passes` (each finding tagged with its pass): **Bugs** — logic errors,
  broken edge cases, regressions; **Security** — injection, secrets, PII in
  logs; **Compliance** — the change matches its spec.md / plan.md and the
  repo's design principles (CONTEXT.md vocabulary, ADR constraints).
- `## Severity`: Important = would break behavior, leak data, or breach a
  written contract (sync rule, protection rule, `ready-for-agent`
  contract). Style and naming are nits.
- `## Skip-list`: anything `tests/validate.sh` already enforces (the check
  list in AGENTS.md's Commands block — re-checking by eye what the suite
  checks mechanically is waste); `.factory/` (orchestrator-local, untracked
  by design); generated files (none today).
- `## The loop`: reviewers give reviews per this policy (`code-review`
  skill's two axes + mandatory `adversary` pass on agent-produced diffs);
  authors receive and resolve them — a finding is resolved by a fix commit
  or an explicit carried-forward note with an owner, never by silence.

**Ordering:** REVIEW.md lands in its own ticket, and the doc ticket is
`blocked_by` it — the Deploy section references REVIEW.md by path, so the
reference must resolve at the section's landing sha.

### The merge gate (what a unit of work owes before merge)

In this repo the unit presented for merge is a ticket's diff range at close
(no PR flow yet); for consumers it is a literal PR. The gate is the same
checklist at either seam:

1. Review findings resolved or carried with an owner.
2. `tests/validate.sh [<range>]` run pasted, exit 0, range explicit
   (Test §1 — referenced, not duplicated).
3. Adversary verdict on the diff recorded.
4. Human checkoff for flagged-risk classes (autonomy table below).
5. UI tickets only: preview proof pasted (screenshot / recording /
   standing link). Consumer obligation; no example artifact in this repo.
6. Branch-protection proof pasted (manual, below) — only for tickets that
   touch the merge path; every other close marks it "n/a — not a
   merge-path ticket".

### Branch-protection verification (manual, offline-suite-safe)

Procedure written into the Deploy section: run
`gh api repos/{owner}/{repo}/branches/main/protection` and paste the result
at close of any ticket that touches the merge path; the paste either shows
the protection fields (required approvals, status checks) or records the
absence. **Today's verified state: 403 — protection unavailable on this
private free-plan repo.** The contract therefore states plainly: until #1
unfreezes (or the plan changes), the human checkoff is the only enforcement,
and the gate does not pretend the server provides one. `tests/validate.sh`
stays offline (Test §5): no branch-protection check joins the suite.

### Autonomy boundaries

Written into the Deploy section as a two-class table:

| Change class | Who merges |
|---|---|
| Flagged risk: any surface a suite check asserts on (`tests/`, the synced trio, AGENTS.md, `intent/**`, `docs/adr/**`, `plugin/**`, `.agents/skills/**`, CONTEXT.md), plus `docs/agents/` (tracker mechanics), security/trust-boundary surfaces, and irreversible or destructive operations | Human checkoff, recorded in the thread, after a green gate |
| Everything else (prose, intents/specs after their own approval gates, internal refactors with a green gate) | Agent may land; the gate's evidence is the record |

Hooks/CI/release gates, when they exist (#1), are always human-authorized.

### stage-parity update (verbatim, one sha with the doc change)

Check change in `tests/validate.sh`:

- Alternation `^## (Plan|Design|Build|Test)\b` gains `Deploy` (doc + SKILL),
  README alternation `^(Plan|Design|Build|Test) ─+►` gains `Deploy`;
  expected count `444` → `555`.
- Post-landing counts (verified against today's tree): doc 4→5 (new
  `## Deploy` section); SKILL already has `## Deploy — gated` → 5 once the
  paragraph is rewritten; README already has a `Deploy ──►` line → 5 once
  the line is rewritten. The landing sha therefore reads 555.
- Witness rows: keep `expect FAIL 1b41a31 stage-parity` (re-verified: under
  the new alternation that sha reads doc 3 / SKILL 5 / README 5 → still
  FAIL, new reason string). **Add three mutation rows** on the HEAD
  worktree, one per leg — the historic sha fails for reasons unrelated to
  Deploy, so each leg needs its own fail-first (Test §2):
  `grep -v '^## Deploy' docs/engineering-workflow.md` → doc 4 → FAIL;
  `grep -v '^## Deploy' plugin/skills/engineering-workflow/SKILL.md` →
  SKILL 4 → FAIL; `grep -v '^Deploy ' README.md` → README 4 → FAIL.

### Where the words land

- `docs/engineering-workflow.md`: new `## Deploy — review loop, merge gate,
  autonomy boundaries` section after `## Test`, carrying the review loop,
  the gate checklist, the branch-protection procedure + today's 403 state,
  the autonomy table, and the preview-proof obligation. References
  `REVIEW.md` by path.
- `plugin/skills/engineering-workflow/SKILL.md`: the `## Deploy — gated`
  paragraph (today: "Standard pipeline; branch protection on main is the
  gate") rewritten to the compressed contract.
- `README.md`: the `Deploy ──► branch protection is the gate` line rewritten
  to name the review loop + merge gate.
- All three plus `tests/validate.sh` (check + witness row) in **one sha** —
  the sync execution rule and Test §4 both bind that commit.
- CONTEXT.md: candidate new glossary terms **merge gate** and **preview
  proof**; **review loop** if the domain-modeling pass finds it
  load-bearing. Same commit as the section.
- AGENTS.md: unchanged — the check list gains no names (`agents-commands`
  unaffected); the Commands block prose already covers the suite.

### Seams

One seam, already existing: the closing comment (this repo) / PR thread
(consumers) carrying pasted evidence. Deploy extends what that comment must
contain; it adds no second surface. REVIEW.md is read by reviewers at review
time — the same read-a-doc seam CONTEXT.md already uses.

### ADRs

Follows 0001 (spec by path) and 0002 (children of #12). No new ADR expected:
the REVIEW.md-is-subordinate decision is visible in the Deploy section
itself, and the autonomy table is a docs-first statement, not a hard-to-
reverse mechanism. If the ticket cut surfaces a real trade-off, the next
number is 0003. **Landmine:** never write an `ADR <number>` reference in
the synced docs, `intent/`, or `plugin/` before that ADR exists —
`adr-refs` greps those trees and would FAIL the landing sha. Refer to "the
next ADR" without digits.

## Constraints

### System

- Sync rule: doc change ⇒ trio in one commit. Sync scope unchanged:
  REVIEW.md is not a fourth synced file.
- `tests/validate.sh` stays offline, stdlib/shell only (Test §5); the
  stage-parity edit changes an alternation and a literal, nothing else.
- One sha lands doc + SKILL + README + check + witness (sync execution
  rule; Test §4 — the check is updated by the diff it measures, cited to
  this issue).
- No hooks, no CI wiring, no server-side enforcement (#1, frozen).

### UX

- A fresh agent reads the Deploy section and can state what a close owes
  without chat history; REVIEW.md stands alone as review instructions.
- State that must never occur: the contract implying branch protection
  exists today — the 403 absence is stated, not papered over.

### Security

- The autonomy table is the governance surface: the flagged-risk list must
  be exhaustive for this repo's contract surfaces (tests/, synced trio,
  AGENTS.md, plugin hooks, skill frontmatter) — a class missing from the
  list is a self-merge hole.
- With branch protection absent, direct push to main is possible; the
  contract names the human checkoff as the only enforcement rather than
  claiming a server gate.

## Testing decisions

- Proof for the doc ticket: pasted `tests/validate.sh origin/main..HEAD`
  run (exit 0; sync-rule passes on the landing sha) **and** pasted
  `tests/validate.sh --witness` run showing both stage-parity rows behaving
  (historic sha FAIL, Deploy-removal mutation FAIL).
- Fail-first for the check change is the mutation witness row — recorded in
  the suite itself, replayed by `--witness`, not a one-time paste.
- Proof for the REVIEW.md ticket: the file exists with the four pinned
  `##` sections (passes / severity / skip-list / loop), shown by
  `grep -n '^## ' REVIEW.md`, and the ticket's own close runs the loop it
  defines (review + adversary verdict on its diff).
- External behavior only: no test of prose content beyond what the suite
  already checks; the Deploy section's quality gate is the operator's
  approval, not a grep.

## Out of scope

- Hooks / CI wiring / sandbox / containers — #1, frozen.
- Enabling branch protection for real (plan upgrade or going public) —
  operator's infrastructure decision, recorded as today's state only.
- Adopting a PR flow for this repo — the gate binds to ticket closes until
  #1 or a consumer need changes that.
- Editing the `code-review` skill to cite REVIEW.md — the Deploy section
  binds reviewers to the policy; a skill edit is a follow-up if wanted.
- Visualization runtime, eval harness, sync-rule expansion, reopening
  #2/#3/#4/#9 contracts.

## Open questions

1. CONTEXT.md glossary: **merge gate** + **preview proof** in, **review
   loop** only if load-bearing — owner: domain-modeling pass at the doc
   ticket; not blocking.
2. `code-review` skill citing REVIEW.md — owner: operator; default: no edit
   this work, follow-up if the skill should name the policy file; not
   blocking.
