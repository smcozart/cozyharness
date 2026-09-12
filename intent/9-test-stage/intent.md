# Intent: Test is its own stage — one local command is the proof gate

**Issue:** #9 · **Status:** approved · **Type:** system-change

## Problem

Build (#4) folded Test into Build via "paste your acceptance-criteria output."
That proves the ticket's own claims and nothing else: nothing in the repo
re-checks the structural rules it already has (sync rule, intent/spec/ADR
layout, ADR references), Build QC findings (#8) are closed by reading rather
than by a check that would fail if the pattern came back, and there is no
single command a closer, reviewer, or orchestrator can run to say "healthy."
The workflow doc has Plan, Design, and Build sections and no Test section;
the plugin skill has a Test paragraph the canonical doc does not.

## Desired outcome

Stage 4 (Test) is codified with the same rigor as #2/#3/#4: a Test section in
`docs/engineering-workflow.md` (synced per the sync rule), and one local
command — `tests/validate.sh` — that exits non-zero on any structural or
regression failure. Every ticket close pastes that run's output next to its
acceptance-criteria output. Every check in the suite has a recorded fail-first
witness (a historic commit or a documented mutation on which it fails for the
expected reason), so no tautological green joins the suite. The invocation
contract lives in AGENTS.md as a Commands block whose check list is itself
verified by the suite.

## Scope

- The Test gate definition: what a ticket owes at close beyond Build §5.
- `tests/validate.sh`: one command, stdlib/shell only, offline, exit code is
  the verdict. Its static half (structure + sync rule) and its regression
  half (claim checks from the #8 corpus).
- Fail-first witness discipline, and a runnable form of it for the checks
  that have an in-tree bad version.
- Protection rule: review-reject any diff that weakens a check it is being
  measured against.
- Commands block in AGENTS.md; Test section in the workflow doc + synced
  SKILL.md + README line.
- Eval-vs-test boundary written down: #8 stays the ledger; the eval harness
  is deferred.

## Non-goals

- CI hooks, branch protection, any server-side enforcement — issue #1.
- An eval harness (prompt+check pairs replayed against agent config) — lands
  when #1 unfreezes; #8 remains the ledger meanwhile.
- Bootstrap smoke as part of the default suite — it clones from the network
  and installs Claude plugins on the host; it stays the manual regression
  procedure recorded in #6.
- TypeScript type-checking of `.pi/extensions/*` — no `tsc` in the repo, and
  adding a toolchain for a docs-heavy repo fails the stdlib-first rule.
- Reopening #2/#3/#4 contracts.

## Acceptance criteria

- `tests/validate.sh` exists, runs from a clean checkout with only bash,
  git, grep/awk, and python3 (stdlib), exits 0 on `main` and prints one
  `ok:`/`FAIL:` line per check.
- Every check has a witness, historic sha or one-line mutation (one per
  clause for two-clause checks), and
  `tests/validate.sh --witness` runs all of them: bad sha / mutated tree →
  FAIL, good sha → ok; it exits 0 only if every row behaves as expected.
  The verbatim patterns and shas are in the spec, not deferred to tickets;
  the sha-backed ones were verified by hand before the spec was committed.
- The dangling ADR reference at `docs/engineering-workflow.md:204` is
  resolved (rewrite, or write the next contiguous ADR and repoint), with `adr-refs` shown
  failing on `1b41a31` and passing after.
- `sync-rule` is symmetric (canonical doc **or** plugin SKILL.md touched ⇒
  all three touched) and range-aware (`<range>` arg, dirty tree, or last
  commit, where dirty = `git diff --quiet HEAD` non-zero, tracked files only);
  `a6519a9` → FAIL, `571afe4` → ok.
- `docs/engineering-workflow.md` has a `## Test` section; the same commit
  touches `plugin/skills/engineering-workflow/SKILL.md` and `README.md`
  (the sync check in the suite passes on that commit).
- AGENTS.md carries a Commands block naming `tests/validate.sh`, its
  `--witness` mode, and the check list (verified by `agents-commands`); the
  next closed ticket's proof comment includes that run.
- Each child ticket closes with pasted acceptance-criteria output AND a
  pasted `tests/validate.sh` run.

## System-intent alignment

Purpose 3 (proof replaces claim) — makes the proof a re-runnable command
instead of a per-ticket paste; purpose 5 (portable) — shell + stdlib, no CI
dependency, runs under any host.
