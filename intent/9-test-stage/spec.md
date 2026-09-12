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
3. As a fresh agent in any host, I want a Commands block in AGENTS.md with
   the exact healthy output, so that I know what to run and what "green"
   looks like without chat history.
4. As a maintainer, I want the sync rule checked mechanically on a commit
   (touch `docs/engineering-workflow.md` ⇒ touch the plugin SKILL.md and
   README.md in the same commit), so that drift is caught at close, not at
   retro.
5. As a maintainer, I want structural rules checked (intent dirs, spec
   headers, ADR numbering, ADR references resolving), so that the join-key
   chain (issue ↔ intent ↔ spec ↔ ADR) can't silently break.
6. As a reviewer, I want every adversary finding from Build that was fixed by
   changing text (#8 corpus) encoded as a claim check, so that a rewrite can't
   reintroduce it unnoticed.
7. As a reviewer, I want every check to carry a fail-first witness — a
   historic commit sha, or a documented mutation — and a runnable
   `--witness` mode for the sha-backed ones, so that no tautological green
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
`$fail`. No framework, no per-check files. Two halves:

**Static half (repo rules)**

| Check | Rule | Witness |
|---|---|---|
| `sync-rule` | If the commit under test touches `docs/engineering-workflow.md`, it also touches `plugin/skills/engineering-workflow/SKILL.md` and `README.md`. Default commit under test = `HEAD`; a sha argument overrides. | Historic: `a6519a9` (touched 1 of 3) must fail; `571afe4` (3 of 3) must pass. |
| `stage-parity` | Each of `## Plan`, `## Design`, `## Build`, `## Test` exists as an H2 in both the canonical doc and the plugin SKILL.md; README's phase map names all four. | Historic: `HEAD` today fails (`## Test` missing from the canonical doc) — the fix lands in the doc ticket, giving a real before/after. |
| `intent-layout` | Every `intent/<n>-<slug>/` matches `^[0-9]+-[a-z0-9-]+$`, contains `intent.md` whose `**Issue:** #<n>` matches the dir number; a `spec.md`, if present, has `**Issue:** #<n>` and `**Intent:** \`intent/<n>-<slug>/intent.md\`` matching its own path. | Mutation: rename a dir or edit the header in a scratch worktree. |
| `adr-numbering` | `docs/adr/` files match `^[0-9]{4}-[a-z0-9-]+\.md$`, numbers start at 0001 and are contiguous; each has an `**Issue:**` header. | Mutation: add `docs/adr/0009-x.md` in a scratch worktree. |
| `adr-refs` | Every `ADR NNNN` / `ADR-NNNN` mention in AGENTS.md, CONTRIBUTING.md, README.md, CONTEXT.md, `docs/engineering-workflow.md`, `docs/adr/`, `intent/`, `plugin/` resolves to `docs/adr/NNNN-*.md`. Vendored skills and `docs/agents/*.md` (example prose) excluded. | Historic: `HEAD` today fails on `docs/engineering-workflow.md` "ADR 0007". Resolve the dangle in the same ticket (write the ADR it alludes to, or drop the parenthetical) so the suite is green at merge. |
| `hooks-json` | `plugin/hooks/hooks.json` parses; top-level key is exactly `hooks`; event keys ⊆ Claude Code's hook events. `python3 -m json.tool` + a five-line key check. | Mutation: trailing comma. |
| `skill-frontmatter` | Tracked skills only (`plugin/skills/*`, `.agents/skills/ponytail`, `.agents/skills/factory-orchestrator`): file starts with `---`, has `name:` and `description:` before the closing `---`, `name` equals the directory name. grep/awk, no YAML lib. | Mutation: delete `name:` line. |
| `skill-copies` | `plugin/skills/factory-orchestrator/SKILL.md` and `.agents/skills/factory-orchestrator/SKILL.md` are byte-identical (the #5 contract). | Mutation: one-char edit to one copy. |

**Regression half (claim checks from #8)**

One grep-shaped assertion per corpus item whose fix was textual; each carries
the corpus line and its bad sha in a comment. Seeded set (the ticket pins the
exact patterns):

| Corpus item | Claim | Bad sha (must fail) | Good sha (must pass) |
|---|---|---|---|
| T1 MED trust wording | factory-orchestrator SKILL.md does not say `-p` "REFUSES" the trust dialog and does not say it "skips" it interactively-wrong (exact pattern pinned by ticket) | `da9eb33` | `4e9b547` |
| T1 LOW `>log` clobber | no bare `>log` redirect without a per-ticket filename | `da9eb33` | `4e9b547` |
| T1 MED session-id | spawn line captures a session id / stream-json output | `da9eb33` | `4e9b547` |
| T3 MED label drift | AGENTS.md override sentence names `/to-spec` + `ready-for-agent`, not "never auto-apply labels" | `43b63dc` | `92e6a25` |
| T3 MED precedence framing | AGENTS.md contains the literal "Overrides to the vendored skill:" | `43b63dc` | `92e6a25` |

Items with no textual footprint (e.g. "HANDOFF grep fallback reachable on
every spawn path") stay in #8 as eval material, not as grep checks —
listing them as checks would be the tautological-green failure the amendment
forbids.

### `--witness` mode

`tests/validate.sh --witness` iterates a table of `(check, sha, expect)`
triples, runs the check against `git show <sha>:<path>` (or a `git worktree`
at `<sha>` for multi-file checks), and reports `witness ok:` when the result
matches `expect`. Exit non-zero if any witness does not behave. Mutation
witnesses are documented in the check's comment, not automated — the amendment
requires the evidence, not the automation; ticket proof pastes one mutation
run per mutation-witnessed check.

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
- AGENTS.md gains a `## Commands` block: `tests/validate.sh` with the exact
  healthy output pasted (the check list as `ok:` lines + summary + exit 0),
  and `tests/validate.sh --witness`.
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
| structure checks | **in** | Cheap, join-key protecting, real failure in tree today (ADR 0007). |
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
  pasted in the ticket. Mutation-witnessed checks paste one mutation run each.
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

1. Resolve `ADR 0007` by writing the ADR it alludes to ("no load-bearing
   sessions") or by dropping the parenthetical? — owner: operator; not
   blocking (either satisfies `adr-refs`; ticket author picks and says so).
2. Does the "validate.sh checks artifacts; evals are not tests" boundary earn
   an ADR? — owner: operator at ticket cut; not blocking.
3. Reviewer/adversary agent prompts (`.pi/agents/*.md`) get the protection
   rule sentence — in this work or a follow-up? — owner: operator; not
   blocking (default: this work, one line each).
