# Engineering Workflow: Matt Pocock Skills + ADRs + Herdr Orchestration

This is the standard process, extracted from how this repo actually runs. All machines
running Claude Code or pi should follow it. Prerequisites: Matt Pocock skills installed
(`mattpocock/skills`), `gh` CLI, and for parallel builds the `herdr` CLI.

## Pipeline (in order)

```
setup (once per repo)
  → /to-questionnaire → /to-spec → /to-tickets → /triage loop
  → /implement (per ticket, test-first) → /code-review + adversarial pass
  → ADRs + CONTEXT.md maintained continuously (domain-modeling)
  → /retro at milestones, /handoff at session end
```

## One-time repo setup

**`/setup-matt-pocock-skills`** — run once per repo before any other skill. Decides and
records:

- **Issue tracker**: GitHub Issues by default (remote, shared, API-addressable — fits
  multi-session/multi-agent work; see ADR 0004). Local markdown only for non-GitHub repos.
- **Triage labels**: the five canonical triage-role labels, plus `ready-for-agent`
  ("blockers resolved, acceptance criteria defined").
- **Domain docs**: `CONTEXT.md` at repo root, ADRs in `docs/adr/NNNN-slug.md`.

## Stage-by-stage map

| Stage | Skill | When / where |
|---|---|---|
| Elicit requirements | `/to-questionnaire` | New feature with unknowns. Converts vague asks into answerable questions. |
| Write the spec | `/to-spec` | After questionnaire. Spec is the durable artifact; reference it from issues. |
| Break into tickets | `/to-tickets` | After spec. Tracer-bullet vertical slices; blocking edges declared per ticket (GitHub native blocking links). Never horizontal layers. |
| Groom the queue | `/triage` | Continuous. State machine of triage roles → issues end as agent-ready briefs labeled `ready-for-agent`. AI-generated comments carry the AI-triage disclaimer. |
| Stress-test thinking | `/grilling` (or `/grill-me`, `/grill-with-docs`) | Before accepting a spec, an architecture, or an agent's plan. Cheap insurance; use liberally at decision points. |
| Implement | `/implement` | Per ticket, one ticket per session. Test-first (red-green slices). Lean: stdlib first, shortest working diff. |
| Test discipline | `/tdd` | Default mode inside implement. Every test justifies itself — guards behavior no other test covers. |
| Debugging | `/diagnosing-bugs` | When something is broken/slow, not during planned work. |
| Review | `/code-review` | After each diff (or each batch). Two axes: standards + spec. |
| Adversarial review | `adversary` subagent (pi) | Mandatory on agent-produced diffs. Breaks the author-boss bias loop. Claude equivalent: a second review pass with "assume this is wrong" instructions. |
| Record decisions | `domain-modeling` | ADR bar: hard to reverse, surprising without context, a real trade-off. One paragraph, `docs/adr/NNNN-slug.md`, **commit and push** — an unpushed ADR is invisible. Visible in code ⇒ no ADR. |
| Shared vocabulary | `CONTEXT.md` via `domain-modeling` | Update when terminology shifts; consumers read it before issues. |
| Milestone retro | `/retro` | At milestones or when a failure pattern repeats. Feed findings into ADRs or process edits. |
| Session end | `/handoff` | Compact conversation → handoff doc for the next session. References artifacts by path; never duplicates them. |

## Orchestration layer (multi-agent builds)

**`factory-orchestrator` skill + `herdr`** — when tickets are parallelizable and you want
workers, not a single session. Key rules (full detail in the skill):

1. Orchestrator never writes code; it dispatches, watches, and runs QC itself.
2. One ticket per worker session, fresh pane per ticket (`herdr tab create` →
   `herdr agent start --kind pi` → prompt from the template in the skill).
3. Orchestrator pre-answers the 2–3 ticket ambiguities **in the worker prompt**.
4. GitHub is the claim; the orchestrator's terminal is the proof. Run acceptance
   criteria and the full suite yourself before blessing.
5. Workers end with a `HANDOFF:` direct ping to the orchestrator pane before idling.
6. Two consecutive QC failures anywhere → halt the chain, revisit the prompt/design
   with the operator.
7. No load-bearing sessions: any pane can die and work resumes from GitHub + pushed
   commits (ADR 0007).

The full skill text lives at `.agents/skills/factory-orchestrator/SKILL.md` in this repo
(it's self-contained except for `.factory/design.md`, which is build-specific — replace
that per project). Copy it into `.agents/skills/` (pi) or `.claude/skills/` (Claude Code)
on the target machine, or let the repo's git checkout supply it.

## Non-negotiables (the parts that make it work)

1. **GitHub Issues is the tracker.** Issue numbers are the join key between sessions,
   agents, and machines. No side-lists in chat, no parallel TODO files.
2. **Blocking edges in the tracker**, not in anyone's head. Dispatch order reads off
   the graph.
3. **`ready-for-agent` is a contract**: blockers resolved + acceptance criteria defined.
   Agents never pick up unlabeled work.
4. **ADRs are pushed immediately.** Decisions live in `docs/adr/`, not in session memory.
5. **Proof over claim.** Whoever closes work runs the verification commands and pastes
   the output into the issue.
6. **Artifacts over conversation.** Specs, ADRs, and issues are durable; chat is not.

## Do we need a documentation skill on top of this?

No. Documentation here already has three owners, and a fourth would overlap all of them:

- `domain-modeling` → CONTEXT.md + ADRs (the "why" and the vocabulary)
- `/to-spec` → specs (the "what we're building")
- `/handoff` → session continuity

What's worth adding instead is a lightweight rule, now captured above: **user-facing docs
(`README`, `docs/`) get updated in the same PR as the change they describe**, same bar as
tests. If docs debt ever becomes real, revisit — don't pre-build a skill for it.
