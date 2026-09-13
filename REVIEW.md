# Review every diff against this policy. Findings are tagged with the pass that produced them.

## Passes

Run all three on every diff. Tag each finding with its pass.

- **Bugs** — logic errors, broken edge cases, regressions.
- **Security** — injection, secrets, PII in logs.
- **Compliance** — the change matches its spec.md / plan.md and the repo's design principles (CONTEXT.md vocabulary, ADR constraints).

## Severity

- **Important**: would break behavior, leak data, or breach a written contract (sync rule, protection rule, `ready-for-agent` contract).
- Style and naming are nits.

## Skip-list

Do not review by eye what a check enforces mechanically:

- Anything `tests/validate.sh` already enforces: the synced trio, `intent/` layout, ADR numbering and references, `hooks.json`, skill frontmatter and copies, the AGENTS.md Commands block, and the t1/t3 regression claims.
- `.factory/` — orchestrator-local, untracked by design.
- Generated files — none today.

## The loop

- Reviewers give reviews per this policy: the `code-review` skill's two axes plus a mandatory `adversary` pass on agent-produced diffs.
- Authors resolve findings by a fix commit or an explicit carried-forward note with an owner — never by silence.
