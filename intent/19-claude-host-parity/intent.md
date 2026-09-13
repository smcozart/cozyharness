# Intent: Claude Code host parity — clone-and-launch usability for the second host

**Issue:** #19 · **Status:** approved · **Type:** system-change

## Problem

The Harness claims host-neutrality ("lives in the repo, not in any one tool" — SYSTEM-INTENT purpose 5), but a fresh clone + `claude` launch does not find the workflow: no `CLAUDE.md` (Claude Code doesn't read `AGENTS.md` by default), no `.claude/skills/` copies (the factory-orchestrator host appendix's own Claude mechanism), and no repo-side verification that the Claude seam exists. Host-neutrality is claimed but only half-shipped.

## Desired outcome

A fresh clone + `claude` launch reaches the same contracts a `pi` launch does: AGENTS.md content via `CLAUDE.md`, both repo skills via `.claude/skills/`, enforced by the suite so the copies can't rot. Host-neutrality is verified by an authored, reproducible run executed against a fresh Claude session, its evidence pasted at close.

## Scope

- `CLAUDE.md` at repo root: a pointer to `AGENTS.md` (single source; no duplicated contract text).
- `.claude/skills/engineering-workflow/SKILL.md` and `.claude/skills/factory-orchestrator/SKILL.md`: copies of the plugin skills (the factory-orchestrator copy byte-identical, matching the `.agents/skills/` precedent).
- `tests/validate.sh`: extend `skill-copies` to verify the `.claude/skills/factory-orchestrator` copy is byte-identical (same check, second target — widening, cited to #19 per Test §4).
- **Authored host-verification run:** a Claude-host test run (a prompt file + expected observations, checked into the repo under `.claude/`) that a fresh Claude session executes; the run's transcript is the close evidence. The orchestrator spins it up in a separate herdr session after the landing and reports the result on the ticket.
- Note documenting the Matt Pocock skills as a per-machine prerequisite (`mattpocock/skills`), not repo files.

## Non-goals

- Vendoring the Matt Pocock skills into this repo — external dependency, installed per-machine.
- Claude plugin marketplace packaging — `.claude/skills/` copies are the documented mechanism.
- Hook implementations for either host — **#1 is the follow-up, marked per-host** (pi and Claude Code enforce differently; each host's hook config gets its own intent under #1).
- The full Claude-host pipeline pilot — follows this ticket, separate intake.
- Repo splitting — rejected at intake: one repo, thin host seams.

## Acceptance criteria

- `CLAUDE.md` exists and points at `AGENTS.md` without duplicating contract text.
- `.claude/skills/` carries both skills; the factory-orchestrator copy is byte-identical to the plugin and `.agents/skills/` copies; `tests/validate.sh` exits 0 with the extended `skill-copies` (witness updated/re-recorded if the mutation row must widen).
- The authored verification run exists in `.claude/` and is executed in a fresh herdr Claude session after the landing; the transcript is pasted at close showing Claude reaches the contracts.
- The landing's own close runs the merge gate: bare + range + `--witness` pasted, review + adversary verdicts, branch-protection paste (merge-path: touches `tests/validate.sh`), human checkoff.

## System-intent alignment

Purpose 5 (portable — lives in the repo, not any one tool): this closes the gap between the claim and the repo. No amendment to SYSTEM-INTENT.md.