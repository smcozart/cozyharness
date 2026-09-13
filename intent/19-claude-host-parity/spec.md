# Spec: Claude Code host parity — pointers, skill copies, and an authored verification run

**Issue:** #19 · **Intent:** `intent/19-claude-host-parity/intent.md` ·
**Status:** approved · **ADRs:** none (all decisions visible in the artifacts)

## Problem statement

The host-neutrality purpose is half-shipped: a fresh clone + `claude` finds
nothing (no `CLAUDE.md`, no `.claude/skills/`), and nothing in the suite
would notice if it stayed that way.

## Requirements

1. As a Claude Code session in a fresh clone, I want a `CLAUDE.md` pointer,
   so that I reach `AGENTS.md`'s contracts without a human telling me where
   they live. (Pinned as an assumption: the repo's artifacts don't
   corroborate Claude Code's `CLAUDE.md` behavior — the verification run is
   what confirms or falsifies it; if the run shows the pointer is dead,
   the landing is rejected and the mechanism revisited, not shipped anyway.)
2. As a Claude Code session, I want both repo skills in `.claude/skills/`,
   so that the engineering-workflow and factory-orchestrator contracts load
   the same way they do under pi.
3. As the suite, I want `skill-copies` to verify the Claude copies so that
   they cannot silently rot out of sync with the plugin originals.
4. As the operator, I want an **authored verification run** — a prompt file
   plus expected observations checked into `.claude/` — so that host parity
   is demonstrated by a reproducible fresh-session run, not a one-off
   anecdote.
5. As a fresh operator cloning on any machine, I want the Matt Pocock skills
   prerequisite documented, so that the intake→spec UX works after one known
   install step.

## Design concerns

- **`CLAUDE.md` content (pinned):**

  > # The Harness
  >
  > Read `AGENTS.md` — it is the single source of the workflow, commands,
  > and contracts for this repo. This file is only the pointer.
  >
  > - Workflow: `docs/engineering-workflow.md` (six-stage loop)
  > - Review policy: `REVIEW.md` · Vocabulary: `CONTEXT.md`
  > - Skills: `.claude/skills/` (copies of `plugin/skills/`)
  > - Proof gate: `tests/validate.sh [<range>]` · `--witness` for fail-first
  > - Prerequisite: install Matt Pocock skills once per machine
  >   (`mattpocock/skills`) — `/to-spec`, `/triage`, `/to-tickets` are not
  >   repo files.

- **Skill copies:** `.claude/skills/engineering-workflow/SKILL.md` and
  `.claude/skills/factory-orchestrator/SKILL.md` copied from
  `plugin/skills/`; the factory-orchestrator copy byte-identical to both the
  plugin copy and the existing `.agents/skills/` copy.

- **`skill-copies` widening** (in `tests/validate.sh`, same sha): today the
  check runs exactly ONE comparison — plugin factory-orchestrator ↔
  `.agents/skills/` byte-identity (`tests/validate.sh` `check_skill_copies`).
  This landing adds TWO new comparisons inside the same check, each its own
  `cmp` with its own distinct `why` string naming the mismatching pair (do
  not reuse/overwrite one `why` variable — misattributed witness failures
  are a known trap with multi-comparison functions):
  1. plugin factory-orchestrator ↔ `.claude/skills/factory-orchestrator/`
     SKILL.md — three-way byte-identity with the existing pair;
  2. plugin engineering-workflow ↔ `.claude/skills/engineering-workflow/`
     SKILL.md — a NEW comparison (no `.agents` copy of engineering-workflow
     exists; do not assume one).
  Mutation witness row: append `x` to the `.claude` factory copy → FAIL
  (same pattern as the existing skill-copies row). The check is widened,
  not loosened, cited to #19.

- **Authored verification run** at `.claude/verify-host.md` (pinned shape —
  the file IS the run; its content is given as the prompt to a fresh Claude
  session):
  1. "You are a fresh session in the cozyharness clone. Answer, citing the
     file paths you actually read: (a) what is the workflow in this repo and
     where is its canonical contract? (b) what command proves a diff, and
     what does `--witness` do? (c) if you picked up a `ready-for-agent`
     ticket, what is your read order? (d) what is the review policy file and
     what are its three risk classes?"
  2. Expected observations: the session reads `CLAUDE.md` → `AGENTS.md` →
     `docs/engineering-workflow.md`; names `tests/validate.sh`; names
     REVIEW.md and Bugs/Security/Compliance; cites the Design §7 read order.
  3. Pass bar (pinned): the transcript must show evidence of READING, not
     just plausible answers — the session must open `AGENTS.md` and cite
     content not present in `CLAUDE.md`'s pointer text (e.g. the Design §7
     read order or the `--witness` fail-first rule), and name REVIEW.md's
     three risk classes. Plausible answers without read evidence = FAIL.
  4. Execution mechanics (pinned): the ORCHESTRATOR (not the T1 worker)
     executes the run AFTER the landing sha is on main, per the
     factory-orchestrator appendix §"Claude Code headless" mechanics (fresh
     tmux window, `claude -p --output-format stream-json` with output
     redirected to a per-run log file — append-safe, per the t1-log-clobber
     contract), and pastes the transcript on #19. T1's close does NOT paste
     the transcript; T1's acceptance criterion is that the run file exists
     and the orchestrator's post-landing execution is reported on the
     ticket before the parent close.

- **Ticket cut: one ticket** (T1) — the whole landing is one sha; splitting
  buys nothing. The verification run is executed by the orchestrator
  post-landing (mechanics above), not by the worker. Merge-path (touches
  `tests/validate.sh`): branch-protection paste + human checkoff owed.

- **Seam under test:** the existing `skill-copies` check, widened. The
  verification run is deliberately NOT a suite check (Test §5 — it invokes a
  model; the suite stays offline).

## Constraints

### System

- Suite stays offline; no check shells out to `claude` or `pi`.
- `CLAUDE.md` must not duplicate contract text (drift risk) — pointer only.
- Sync rule untouched: `CLAUDE.md` and `.claude/` are not trio members.
- No new check names (CHECKS list pinned by `agents-commands`).

### UX

- A fresh Claude session must reach the workflow in one pointer hop; no
  dead-end files.
- The README's host story (if touched) must match the trio — but this
  landing should not need to touch the trio at all.

### Security

- None: pointer file, byte-identical copies, check widening. No trust
  boundary crossed; the verification run prompt contains no secrets and
  instructs read-only behavior.

## Testing decisions

- Mechanical: extended `skill-copies` with its mutation witness — proof is
  the three validate runs pasted at close.
- Behavioral: the authored `.claude/verify-host.md` run — one fresh session
  executed by the orchestrator post-landing, transcript pasted on #19;
  the operator holds the judgment call on "reached the contracts" under the
  pinned pass bar.
- Prior art: the `skill-copies` check itself (Deploy-era); replicate the
  same byte-identity mechanics for the second target.

## Out of scope

- Vendoring Pocock skills; marketplace packaging; hooks (#1, per-host
  follow-up); the pipeline pilot (separate intake); repo splitting.

## Open questions

- None blocking.