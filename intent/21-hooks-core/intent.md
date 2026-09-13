# Intent: Hooks — deterministic local gates, shared by pi and Claude Code

**Issue:** #21 · **Status:** approved · **Type:** system-change

## Problem

The process contracts are advisory — the skills make them *likely*, nothing
makes them *required*. The one violation that has cost repeatedly is also
the cheapest to catch: the sync rule (a commit touching the workflow doc
must carry all three renderings) and a red tail landing on main. #1 already
scopes enforcement as "deterministic gates behind advisory skills — not a
hook for everything."

## Desired outcome

A deterministic hook core shared by both hosts via git hooks (host-neutral —
Claude and pi leave the same commits behind, so the same git seams work),
gating the two cheap failures at the seam. A clean push is silent; a covered
failure prints exactly one line and blocks the action. Nothing judges;
only the deterministic check gates.

## Scope

- `.githooks/pre-push`: run `tests/validate.sh [origin/main..HEAD]`; non-zero blocks the push.
- `.githooks/pre-commit`: the sync-rule check (doc → SKILL.md + README.md together); fail-fast.
- A Claude Code `PostToolUse` advisory for "close without proof" — advise-only (`exit 0`).
- `bootstrap.sh` installs `.githooks/` idempotently (`git config core.hooksPath`).
- UX rules: silent when passing; one-line + exit≠0 on a covered fail; no per-run nag; no judgment in a hook.

## Non-goals

- No CI or branch-protection enforcement (403 on this private repo). These are local guardrails, never a pretending server gate.
- No hooks that simulate judgment (ADR bar, quality/scope calls) — stays with the human review loop.
- No new check inside `tests/validate.sh`; hooks only RUN existing checks at the seam.

## Acceptance criteria

- `bootstrap.sh` installs `.githooks/`; re-run is a no-op.
- pre-push blocks a red range (one line, nonzero), passes a green range silently.
- pre-commit blocks a sync-rule violation, passes a clean commit.
- PostToolUse advisory runs and exits 0.
- Reproduce on a throwaway branch (fail beat → green), forking proof pasted at close.

## System-intent alignment

Purpose 3 (proof replaces claim) — a hook makes the cheapest proof automatic at the seam instead of pasted-later. The human gate remains the real authority. No amendment.
