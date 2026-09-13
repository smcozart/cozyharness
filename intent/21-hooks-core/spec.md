# Spec: Hooks — deterministic host-agnostic git core, plus a Claude-only advisory

**Issue:** #21 · **Intent:** `intent/21-hooks-core/intent.md` ·
**Status:** approved · **ADRs:** none

## Problem statement

The deterministic parts of the contract can be enforced at the git seam —
the one place both pi and Claude Code meet identically — but nothing enforces
them there. The two cheapest violations (a per‑commit sync‑rule miscommit, a
red push) still ship past review. A close‑without‑proof catch exists only as
an event‑level advisor, and that is Claude‑specific.

## Ground truth (verified)

- `check_sync_rule` (`tests/validate.sh`) triggers when a range touches
  **DOC *or* SKILL.md** and then requires all three trio members. A
  first‑line pre‑commit trigger on the doc alone would still let a
  SKILL.md‑only edit slip through; the pre‑commit **and** pre‑push must use
  the same trigger set (DOC or SKILL ⇒ all three).
- `tests/validate.sh` prints one `ok:` line per check plus `N ok, M failed`,
  so running it raw is never "silent". The hooks must **capture the output
  and print it only on failure** (one line + the `--no-verify` note), not
  pipe it through to a green push.
- `bootstrap.sh` hardcodes `1/4…4/4` step labels and a `fail=1` convention;
  a hooks install step must integrate with both (re‑number labels; on a
  config failure set `fail=1`).
- `check_hooks_json` requires sole key `hooks` and `type`+`command` per
  entry — a new `PostToolUse` entry is fine if it has `type`+`command`.
- `.gitignore` does **not** ignore `.githooks/`; the hooks will be tracked
  (and honored `core.hooksPath`).

## Requirements

1. As any contributor, I want a `.githooks/pre-commit` that fails when the
   staged tree touches DOC **or** SKILL.md without all three trio members
   staged — so the sync rule can't be silently broken in a single commit.
2. As any contributor, I want a `.githooks/pre-push` that fails when the
   range `validate.sh` would reject — a red range is blocked unless the
   author runs `git push --no-verify`, or the clone never bootstrapped
   `core.hooksPath` (a local guardrail, not a server).
3. As a fresh clone, I want `bootstrap.sh` to install the hooks idempotently
   (the local `core.hooksPath .githooks`), so the guardrail is on when the
   clone is bootstrapped.
4. As a Claude Code user, I want a `PostToolUse` close‑without‑proof
   advisory that fires on the event and stays advisory (`exit 0`).
5. **UX:** passing hooks are silent; a covered failure prints the suite's
   single relevant line + the `--no-verify` bypass note, exit nonzero. No
   nag, no judgment, no auto‑deny.

## Non-goals

- No CI / branch-protection enforcement (403 on this private repo) — a local
  guardrail, never a pretending server gate.
- No new check in `tests/validate.sh`; hooks only **run** the existing checks
  (or a staged-set mirror of them) at the seam.
- No judgment‑simulating hooks (ADR bar, quality, scope/merge) — stays with
  the human review loop.
- No pi event-advisor in V1 — pi has extension hooks (`spawnHook`) but a
  different mechanism; that's a separate follow‑up under #1, not pretend
  parity.

## Deliverables (one landed unit; no suite surface touches)

1. `.githooks/pre-push` — bash: `tests/validate.sh origin/main..HEAD`.
   Capture output; on **failure** echo one line + the `--no-verify` note and
   exit 1; on success print nothing. Must be `chmod +x`.
2. `.githooks/pre-commit` — bash: on the STAGED set
   (`git diff --cached --name-only`), if DOC **or** SKILL.md present then
   require README.md too (all three staged); fail-fast one line, `exit 1`,
   `chmod +x`.
3. `plugin/hooks/hooks.json` — keep `UserPromptSubmit`; **add** a
   `PostToolUse` advisory entry (`type:"command"`, matcher+command,
   `exit 0`) for close-without-proof. Header comment marks it Claude-only.
4. `bootstrap.sh` — integrate step 4→5 (renumber its `n/4` labels):
   `git config core.hooksPath .githooks` (local, idempotent). Never clobber
   an existing **global** `core.hooksPath`; print "already configured
   (hooks: .githooks)" on a no-op; on config failure set `fail=1`.

## Constraints

- Silent on pass; one line + `exit≠0` on a covered failure; `--no-verify` is
  honored and advertised (bypass is intentional and *recorded* — we don't
  fake a server).
- The advisory is a Claude-Code artifact only; the file header says so.
- `.githooks` is bash + git only — no new language, no dependency added.
- Pre-commit and pre-push must share the same trigger set as the suite's
  sync‑rule (DOC or SKILL ⇒ all three) so they agree.
- No change to `tests/validate.sh`; no new check names.

## Acceptance criteria (runnable; output pasted on #21)

- **Executable & fires:** both hook files committed with `chmod +x`; a
  fatal (a deliberate red shape) actually blocks — verified by observing
  the hook fired, not just that its logic passes on paper.
- **Pre-commit:** doc-only staged commit → blocked; trio-staged commit →
  silent pass; SKILL.md-only staged commit → blocked (the SKILL trigger is
  tested, not assumed).
- **Pre-push:** green range → silent push; a deliberately red range →
  blocked with one line + `--no-verify` note.
- **bootstrap idempotent:** run twice; second prints "already configured",
  exit 0, and leaves an existing global `core.hooksPath` intact.
- **Suite green after hooks.json change:** `tests/validate.sh` exit 0,
  pasted.
- **Advisory:** a manual run shows the advisory line, exits 0, not blocking.
- All seam tests run on a throwaway branch with deliberate resets — never
  raise false-mower issues on main; paste both the blocked and the green
  directions.

## Constraints
- bash + git only; silent pass; one line + exit≠0 on a covered failure;
  `--no-verify` honored; advisory named Claude‑only.

## Out of scope
- pi event-adapter; judgment hooks; CI/protection; new suite checks; any
  server factor.

## Open questions
- None blocking.