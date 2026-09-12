# Spec: Test-stage contract — `tests/validate.sh` as the proof gate

**Issue:** #9 · **Intent:** `intent/9-test-stage/intent.md` ·
**Status:** draft · **ADRs:** none yet (one candidate — see Design concerns)

## Problem statement

A closer today pastes the output of whatever commands the ticket named. That
never re-checks the repo's standing rules, never re-checks a prior defect, and
gives a reviewer nothing to run. This spec must (1) define what proof a ticket
owes at the Test gate, (2) give one local command whose exit code is that
proof, (3) make every check in it earn its place with a fail-first witness,
and (4) keep the suite honest about what it does *not* cover (evals, hooks).

Input: issue #9 seed scope and the **amended** alignment memo (second memo
comment wins). Memo item 4 marked the concrete suite list as proposal-only;
this spec selects from it deliberately (see "Suite selection").

## Requirements

1. As a worker closing a ticket, I want one command (`tests/validate.sh`)
   whose non-zero exit means "not healthy," so that proof is a run, not a
   judgment.
2. As an orchestrator doing QC, I want the same command with the same output
   shape (`ok: <check>` / `FAIL: <check> — <why>`, one line each, summary
   last), so that pasted output in an issue is comparable to my own run.
3. As a fresh agent in any host, I want a Commands block in AGENTS.md that
   names the command and the check list it must print (itself verified by
   the `agents-commands` check, so it cannot go stale), so that I know what
   to run and what "green" looks like without chat history.
4. As a maintainer, I want the sync rule checked mechanically over a change
   set (a range, the dirty tree, or the last commit — touching the canonical
   doc **or** the plugin SKILL.md ⇒ all three synced files touched), so that
   drift is caught at close, not at retro, and a split PR cannot slip past.
5. As a maintainer, I want structural rules checked (intent dirs, spec
   headers, ADR numbering, ADR references resolving), so that the join-key
   chain (issue ↔ intent ↔ spec ↔ ADR) can't silently break.
6. As a reviewer, I want every #8 corpus finding **with a textual footprint**
   encoded as a verbatim claim check (the five listed below; the rest named
   as eval material), so that a rewrite can't reintroduce it unnoticed.
7. As a reviewer, I want every check to carry a fail-first witness — a
   historic commit sha, or a one-line mutation — and a runnable
   `--witness` mode for **all** of them, so that no tautological green
   joins the suite.
8. As a bug-fixer, I want the gate to require the failing case first (red on
   the bad version, for the expected reason, then green), so that fixes are
   proven and not asserted.
9. As a reviewer, I want a written protection rule: a diff that fixes a
   checking surface may not loosen the check it is measured against, and any
   change to `tests/` is review-rejected if it weakens a check without an
   issue reference explaining why.
10. As the operator, I want the Test section codified in the workflow doc
    (synced) with the gate defined, so that Test has the same standing as
    Plan/Design/Build.
11. As anyone reading the suite, I want a stated boundary between tests and
    evals: `tests/validate.sh` checks artifacts; #8 is the eval ledger; the
    eval harness is deferred to #1's unfreeze.

## Design concerns

### The Test gate (what a ticket owes at close)

Build §5 stays. Test adds, in the closing comment:

- the `tests/validate.sh` run (full output + exit code), and
- for bug/defect fixes: the fail-first pair — the check failing on the bad
  version for the expected reason, then passing on the fix.

A close missing either is reopened, same as a failed acceptance criterion.

### One script, two halves

`tests/validate.sh` is a single bash script; each check is a shell function
that prints one `ok:`/`FAIL:` line and flips a `fail` flag; the script exits
`$fail`. No framework, no per-check files. `tests/validate.sh --list` prints
the check names, one per line (consumed by `agents-commands`). Two halves.

Every pattern below is the check, verbatim — not a placeholder for a ticket
to pin. All sha-backed witnesses were run against `git show <sha>:<path>`
before this spec was committed; the transcript is on #9.

**Static half (repo rules)**

| Check | Rule (verbatim) | Witness |
|---|---|---|
| `sync-rule` | Over the *change set under test*, if **either** `docs/engineering-workflow.md` **or** `plugin/skills/engineering-workflow/SKILL.md` is touched, all three of {doc, SKILL.md, `README.md`} are touched. README-only edits pass (it carries non-process content: path table, quick start). Change set = `<range>` argument if given (e.g. `origin/main..HEAD` for a multi-commit PR); else the working tree + index vs `HEAD` if dirty; else `HEAD~1..HEAD`. The Test gate requires the close-time run to pass the ticket's range explicitly. | Historic: `a6519a9` (touched 1 of 3 → FAIL), `571afe4` (3 of 3 → ok). Verified. |
| `stage-parity` | `grep -cE '^## (Plan\|Design\|Build\|Test)\b'` = 4 in both the canonical doc and the plugin SKILL.md; `grep -cE '^(Plan\|Design\|Build\|Test) ─+►' README.md` = 4. | Historic: `1b41a31` → FAIL (doc has 3/4, `## Test` missing; SKILL 4/4; README 4/4). Verified. Fix lands in the doc ticket. |
| `intent-layout` | Every *directory* under `intent/` (the two `TEMPLATE*.md` files are exempt by being files) matches `^[0-9]+-[a-z0-9-]+$`, contains `intent.md` whose `**Issue:** #<n>` equals the dir number; `spec.md`, if present, has `**Issue:** #<n>` and `` **Intent:** `intent/<n>-<slug>/intent.md` `` equal to its own path. | Mutation (automated, see `--witness`): `sed -i 's/#9/#8/' intent/9-test-stage/intent.md` → FAIL. |
| `adr-numbering` | `docs/adr/*.md` names match `^[0-9]{4}-[a-z0-9-]+\.md$`, sequence is exactly 0001..N contiguous; each file has a `**Issue:**` header. | Mutation: `touch docs/adr/0009-x.md` → FAIL (gap). |
| `adr-refs` | Every match of `ADR[ -][0-9]{4}` in AGENTS.md, CONTRIBUTING.md, README.md, CONTEXT.md, `docs/engineering-workflow.md`, `docs/adr/**`, `intent/**`, `plugin/**` resolves to an existing `docs/adr/<NNNN>-*.md`. Vendored skills and `docs/agents/*.md` (example prose) excluded. Because `adr-numbering` forces contiguity, the only way to satisfy a dangling reference is to rewrite it or to write the next-numbered ADR and repoint the text. | Historic: `1b41a31` → FAIL (`docs/engineering-workflow.md:204` references a number no file has). Verified. This spec has been scrubbed so it does not trip its own check. |
| `hooks-json` | `python3 -c 'import json,sys; d=json.load(open("plugin/hooks/hooks.json")); assert list(d)==["hooks"]; [ (h["type"],h["command"]) for ev in d["hooks"].values() for m in ev for h in m["hooks"] ]'` — parses, sole top-level key `hooks`, every entry has `type` + `command`. No external event-name list (would rot). | Mutation: append `,` before the final `}` → FAIL (parse). |
| `skill-frontmatter` | For each tracked skill dir (`plugin/skills/*`, `.agents/skills/ponytail`, `.agents/skills/factory-orchestrator`): line 1 is `---`; a second `---` exists; between them `^name: <dirname>$` and `^description: .+` both match. awk, no YAML lib. | Mutation: `sed -i '/^name:/d' plugin/skills/factory-orchestrator/SKILL.md` → FAIL. |
| `skill-copies` | `cmp plugin/skills/factory-orchestrator/SKILL.md .agents/skills/factory-orchestrator/SKILL.md`. Kept because #5's contract ("both copies, byte-identical, one commit") has no other guard and the check is one line. | Mutation: `echo x >> .agents/skills/factory-orchestrator/SKILL.md` → FAIL. |
| `agents-commands` | The `## Commands` block in AGENTS.md contains every name printed by `tests/validate.sh --list`, and no name that `--list` does not print (so the block can't go stale). | Mutation: delete one name from the block → FAIL. |

**Regression half (claim checks from #8)**

One grep assertion per corpus item **that has a textual footprint**; each
carries the corpus line and its bad/good shas in a comment. Items with no
textual footprint (HANDOFF grep fallback reachability, "Poll reads the log"
overclaim, Codex hedge contradiction, vague "triage labels move") stay in #8
as eval material — encoding them as greps would be the tautological green the
amendment forbids. Paths: `FO` = `plugin/skills/factory-orchestrator/SKILL.md`.

| Check | Claim (verbatim) | Bad sha → FAIL | Good sha → ok |
|---|---|---|---|
| `t1-trust-wording` | `FO`: `grep -q 'trust dialog is SKIPPED' && ! grep -qw REFUSES` | `7e8a195` (says "skips", no SKIPPED), `da9eb33` (says REFUSES) | `4e9b547` |
| `t1-log-clobber` | `FO`: `! grep -qE '>log[[:space:]]'` — bare `>log ` redirect; `>log-<ticket>.log` does not match (the `[[:space:]]` is the word boundary). | `da9eb33` | `4e9b547`, `HEAD` |
| `t1-spawn-session` | `FO`: `grep -qE '^- Spawn:.*--output-format'` — the Spawn line itself captures a session id (stream-json elsewhere in the file does not count; that is why `da9eb33` is still bad). | `7e8a195`, `da9eb33` | `4e9b547` |
| `t3-label-drift` | `AGENTS.md`: `` grep -qF 'does NOT apply `ready-for-agent` at spec time' && ! grep -qF 'never auto-apply labels' `` | `43b63dc` | `92e6a25` |
| `t3-precedence` | `AGENTS.md`: `grep -qF 'Overrides to the vendored skill:'` | `43b63dc` | `92e6a25` |

All 13 sha runs above produced the expected verdict (transcript on #9).

### `--witness` mode

`tests/validate.sh --witness` runs every witness in the two tables and
reports `witness ok: <check> @<sha|mutation> expected <FAIL|ok>` per row;
exits non-zero if any row does **not** behave as expected (a bad sha that
passes, or a good sha that fails). Two mechanisms, same check functions:

- **sha witnesses**: single-file checks read `git show <sha>:<path>`;
  multi-file checks (`sync-rule`, `stage-parity`, `adr-refs`) use
  `git worktree add "$(mktemp -d)" <sha>`, removed on exit via `trap`.
- **mutation witnesses**: copy the tree to `mktemp -d`, apply the one-line
  mutation from the table, run the check there, expect FAIL. Automated, not
  one-time evidence — a check whose mutation stops failing is a broken
  check, and `--witness` is how that is noticed.

Requires full history (`git fetch --unshallow` on a shallow clone; the script
says so and exits non-zero rather than reporting a false witness).

### Fail-first semantics (amendment item 3)

- Bug/defect fix: mandatory. Red on bad version, expected reason visible in
  the FAIL line, then green. Both pasted at close.
- Static rule: a historic sha where available; otherwise a mutation witness
  pasted once when the check is added. A static check with neither is not
  admitted.

### Protection rule (amendment item 2)

Written into the Test section and the reviewer/adversary agent prompts: any
diff that touches `tests/` and removes, narrows, or reorders a check away
from the path it is meant to guard is rejected in review unless the diff
cites the issue that retires the rule. The fixer of a checking surface does
not loosen the check in the same diff. No ownership split is claimed.

### Where the words land

- `docs/engineering-workflow.md` gains `## Test — one command, fail-first,
  protected checks` (gate, command, witness rule, protection rule, eval
  boundary), synced to the plugin SKILL.md's existing Test paragraph and the
  README's `Test ────►` line, same commit.
- AGENTS.md gains a `## Commands` block: `tests/validate.sh [<range>]`,
  `tests/validate.sh --witness`, and the healthy shape — `ok: <name>` for
  each name in `--list`, then `N ok, 0 failed`, exit 0. The check names in
  the block are verified by `agents-commands`; no verbatim transcript is
  pasted there (it would be a second staleness surface).
- CONTEXT.md: **Test gate** entry sharpened (currently "pasted verification
  output") to name the command; new terms **check**, **witness** if the
  domain-modeling pass finds them load-bearing.

### Seams

One seam: the script's exit code and line-per-check stdout. Every consumer
(worker close, orchestrator QC, reviewer) reads the same seam. The witness
mode reuses the same check functions against a different tree — no second
implementation.

### ADRs

Follows 0001 (spec by path) and 0002 (children of #9). Candidate new ADR,
decided at ticket time: **"validate.sh checks artifacts; evals are not
tests"** — the boundary is a real trade-off (a suite that could grow into an
eval harness vs. a deliberately small deterministic one). Write it only if
the operator agrees it meets the bar; otherwise the Test section carries the
sentence.

### Suite selection (memo item 4 — proposal list, decided)

| Proposal | Decision | Why |
|---|---|---|
| sync-rule parity | **in** (as same-commit check + stage-heading parity) | Literal text parity is impossible — the three files are different renderings. The commit rule is what CONTRIBUTING actually states, and history holds real bad commits. |
| structure checks | **in** | Cheap, join-key protecting, real failure in tree today (the dangling ADR reference at workflow doc line 204). |
| hooks.json validity | **in** | One line; the plugin's only executable surface. |
| SKILL frontmatter | **in** (grep, tracked skills only) | Product is skills; a broken header is a silent no-load. |
| bootstrap smoke | **out of default run** | Network clone + installs Claude plugins on the host. Stays the manual regression procedure in #6; may become `tests/bootstrap-smoke.sh` opt-in later if someone needs it twice. |
| pi extension `tsc --noEmit` | **out** | No toolchain in repo; adding one for two files fails stdlib-first. Revisit if `.pi/extensions` grows or a `package.json` appears for another reason. |
| issue bodies link specs by path | **out of offline suite** | Needs `gh` + network; the join-key half is covered by `intent-layout`. Add as `--tracker` flag when a second network check justifies it. |

## Constraints

### System

- bash + git + grep/awk + python3 stdlib only. No npm, no pip, no jq
  requirement (jq may be used if present, never required).
- Offline by default; runs from a clean clone in < 5 s.
- Portable across hosts (pi, Claude Code, Codex): the command is the
  contract, not any harness hook.
- Never mutates the working tree; witness runs use `git show` / a temp
  worktree under `$TMPDIR`, removed on exit.

### UX

- Output is one line per check, stable order, then `N ok, M failed`, then
  exit code. No colour requirement. A FAIL line names the file and the
  expected-vs-found in one line.
- States that must not occur: silent exit 0 with no lines; a check that
  prints `ok:` when its target file is missing (missing = FAIL).

### Security

- Trust boundary: the script executes nothing from the files it inspects
  (no `source`, no `eval` of repo content); `git show` output is read as
  text only. `--witness` checks out only shas from this repo's history.
- No secrets touched; `.env` never read.

## Testing decisions

- The suite is the test. Its own correctness is proven by `--witness`: each
  sha-backed check shown red on its bad sha and green on its good sha, output
  pasted in the ticket; each mutation-witnessed check shown red under its
  automated mutation. The `--witness` transcript is part of the ticket proof.
- Good check = external behaviour of an artifact (a file says X / a commit
  touches Y), never the script's internals.
- Prior art: `bootstrap.sh` (function-per-step, `fail=1`, `!!` lines, exit
  code) — reuse that shape verbatim so there is one style of shell in the
  repo.
- Ticket proof for the doc ticket = the sync check passing on its own commit
  sha + `git diff --stat` listing all three synced files.

## Out of scope

- Hooks / CI / branch protection (#1). The script is CI-ready by virtue of
  its exit code; wiring is #1's.
- Eval harness and prompt+check replay — #8 ledger until #1 unfreezes.
- Bootstrap smoke in the default run (see selection table).
- `.pi/extensions` type-checking.
- Retro-fitting proof onto closed tickets #5–#7.

## Open questions

1. The dangling reference at `docs/engineering-workflow.md:204` ("no
   load-bearing sessions"): rewrite the parenthetical, or write it as the
   next contiguous ADR (0003) and repoint? — owner: operator; not blocking
   (either satisfies `adr-refs` + `adr-numbering`; ticket author picks and
   says so). The number it currently names cannot be made to resolve.
2. Does the "validate.sh checks artifacts; evals are not tests" boundary earn
   an ADR? — owner: operator at ticket cut; not blocking.
3. Reviewer/adversary agent prompts (`.pi/agents/*.md`) get the protection
   rule sentence — in this work or a follow-up? — owner: operator; not
   blocking (default: this work, one line each).
