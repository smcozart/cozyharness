# Plan: Test-stage tickets (from spec — APPROVE-WITH-NITS)

## Files that change

- T1 (script): `tests/validate.sh` (new), `tests/README.md` not needed.
- T2 (docs): `docs/engineering-workflow.md`, `plugin/skills/engineering-workflow/SKILL.md`, `README.md`, `AGENTS.md`, `CONTEXT.md`,
  `.pi/agents/reviewer.md`, `.pi/agents/adversary.md`, ADR-0007 dangle resolved at `docs/engineering-workflow.md:204`.

## Order of work

T1 first (script must exist before docs name its output). T2 blocked_by T1.
T1's close may paste exactly two known-pending FAIL lines (stage-parity doc
row, adr-refs @line-204) — recorded, everything else green. T2 turns the
suite green and closes with the same-git-sha sync pass.

## Risks

- T1 scope: keep the script one file, bash+git+grep/awk+python3-stdlib only.
  Playbook prohibits an npm/py toolchain for docs-level checks.
- T2 scope: Test section is a contract VO — keep it the length of the Build
  section, not longer; AGENTS.md Commands block names the command without a
  transcript (agents-commands check validates the block, not a snapshot).

## Proof

T1: `tests/validate.sh` exit 0 except the two recorded known-pending FAILs
+ `tests/validate.sh --witness` full transcript. T2: all three sync files in
one commit, `tests/validate.sh` exit 0, witness-mode transcript still green,
suite/witness outputs pasted on close.
