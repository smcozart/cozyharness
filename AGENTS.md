# CozyHarness

## Agent skills

### Issue tracker

Issues live in this repo's GitHub Issues, managed via `gh` CLI; blocking edges and the `ready-for-agent` contract are defined there. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage-role labels, string-for-string (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` at repo root (created lazily), ADRs in `docs/adr/`. See `docs/agents/domain.md`.

## Engineering workflow

The standard process (planning → tickets → triage → implement → review → ADRs) is documented in `docs/engineering-workflow.md`. Read it before running any engineering skill. It is tool-agnostic: the same pipeline applies under pi, Claude Code, or any agent that can read this repo and run `gh`.

## Pi configuration

Project agents, extensions, and prompts live under `.pi/`. The context footer shows the current repository, model, branch, and live context usage. The project subagent extension is available for scout, planner, reviewer, worker, and adversary work; use `agentScope: "project"` when dispatching it.
