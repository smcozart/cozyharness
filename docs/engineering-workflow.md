# Engineering Workflow: Matt Pocock Skills + ADRs + Herdr Orchestration

This is the standard process, extracted from how this repo actually runs. All machines
running Claude Code or pi should follow it. Prerequisites: Matt Pocock skills installed
(`mattpocock/skills`), `gh` CLI, and for parallel builds the `herdr` CLI.

## Pipeline (in order)

```
setup (once per repo)
  → issue-first intake → intent → /to-questionnaire → /to-spec → /to-tickets → /triage loop
  → /implement (per ticket, test-first) → /code-review + adversarial pass
  → ADRs + CONTEXT.md maintained continuously (domain-modeling)
  → /retro at milestones, /handoff at session end
```

## One-time repo setup

**`/setup-matt-pocock-skills`** — run once per repo before any other skill. Decides and
records:

- **Issue tracker**: GitHub Issues by default (remote, shared, API-addressable — fits
  fits multi-session/multi-agent work; see `docs/agents/issue-tracker.md`). Local markdown only for non-GitHub repos.
- **Triage labels**: the five canonical triage-role labels, plus `ready-for-agent`
  ("blockers resolved, acceptance criteria defined").
- **Domain docs**: `CONTEXT.md` at repo root, ADRs in `docs/adr/NNNN-slug.md`.

## Plan — issue-first intake and work-item intent

Formalized in issue [#2](https://github.com/smcozart/cozyharness/issues/2).

1. **Issue-first intake.** Every request — greenfield or brownfield — becomes
   a GitHub issue before any other artifact. The issue states the problem,
   desired outcome, scope, and non-goals. No side-lists in chat.
2. **One request, one issue.** A conversation containing multiple requests is
   split into separate issues (GitHub sub-issues or `Blocked by:` edges when
   they depend on each other); each gets its own intent and lifecycle. Mixing
   concerns in one issue hides scope from triage and review.
3. **Work-item intent.** After triage clarification, capture the agreed why in
   `intent/<issue-number>-<slug>/intent.md` (start from
   [`intent/TEMPLATE.md`](../intent/TEMPLATE.md)). The issue number is the join
   key: it ties the intent to the issue, later branch, run, PR, and pasted
   proof.
4. **System-intent alignment.** Greenfield work starts from
   [`SYSTEM-INTENT.md`](../SYSTEM-INTENT.md); every work-item intent is checked
   against it. Conflicts either amend SYSTEM-INTENT.md deliberately or rewrite
   the intent.
5. **Approval.** Normal work: conversational — the issue author/maintainer
   approves scope in the issue thread (`ready-for-agent` on the ticket is the
   recorded approval to proceed). High-risk work (security, data loss,
   irreversible migrations, public contracts): explicit review — a designated
   human reviewer signs off in the issue before Build, and the decision gets
   an ADR.
6. **Artifact chain.** intent → spec / ADRs / tickets → plan → code + tests →
   pasted proof. Each stage consumes the previous artifact by reference (issue
   number or path), never by copy-paste.
7. **`plan.md` is Build preparation.** The Plan stage produces the *intent*.
   Any `plan.md` (per-session implementation plan) is written after Design —
   it sequences tickets and ADRs into an execution order and belongs to Build
   preparation, not Plan.

Both flows share this contract: **greenfield** seeds the intent from the brief
or PRD against SYSTEM-INTENT.md; **brownfield** seeds it from the diagnosis,
retro finding, or transcript, and checks it against the same system intent.

## Design — spec.md, ADRs, tickets, and the approval gate

Formalized in issue [#3](https://github.com/smcozart/cozyharness/issues/3).
Design turns an approved intent into three durable artifacts — a spec, the
ADRs the design requires, and ticket issues — then passes the approval gate
that moves work toward `ready-for-agent`.

1. **spec.md lives next to the intent.** The spec for issue `#n` is
   `intent/<n>-<slug>/spec.md`, a sibling of `intent.md` (ADR 0001). The
   issue body links to it by path; the spec header links back to the issue
   and intent. Never copy spec content into the issue body — reference by
   path only, so no stale duplicate can exist.
2. **spec.md required sections** (template + worked example:
   [`intent/TEMPLATE-spec.md`](../intent/TEMPLATE-spec.md)): Problem
   statement · Requirements (numbered user stories) · Design concerns
   (modules, interfaces, test seams — no file paths or code, except
   decision-encoding prototype snippets) · Constraints (system / UX /
   security — an empty security section is a claim; write "none: <why>") ·
   Testing decisions · Out of scope · Open questions (each with an owner;
   none blocking at approval time).
3. **Vocabulary comes from CONTEXT.md.** Specs and ticket titles name
   concepts exactly as root [`CONTEXT.md`](../CONTEXT.md) defines them; a
   term resolved during Design is added to the glossary in the same commit.
   A missing term is a signal: you're inventing language, or you found a
   real gap for `domain-modeling`.
4. **ADRs participate in Design.** A design decision that is hard to
   reverse, surprising without context, or a real trade-off gets an ADR in
   `docs/adr/NNNN-slug.md`, committed and pushed immediately. The ADR names
   the issue it decides for; the spec header lists the ADRs it follows.
   Existing ADRs constrain new design: a contradiction is either surfaced
   explicitly in the spec or resolved by a new ADR that supersedes — never
   silently overridden.
5. **Specs break into vertical-slice tickets** (ADR 0002). Each ticket is a
   GitHub sub-issue of the design issue `#n` (fallback: `Part of #n` at the
   top of the child body + a task list in the parent). Each ticket is a
   tracer bullet: a narrow but complete path through every layer, demoable
   on its own, sized for one fresh context window (wide refactors go
   expand–contract instead — see `/to-tickets`). Each ticket body carries:
   what it delivers, its blocking edges (native `blocked_by` dependencies
   where available; mechanics in
   [`docs/agents/issue-tracker.md`](agents/issue-tracker.md)), runnable
   acceptance criteria, and references to the spec path and governing ADRs.
   Triage labels apply per ticket; the parent design issue closes only when
   every child is closed. The linked-issue graph IS the design.
6. **The approval gate.** Ordinary design is approved conversationally: the
   spec is posted in the issue thread and the maintainer's in-thread
   approval is the record. High-risk design (security, data loss,
   irreversible migrations, public contracts) requires an explicit human
   sign-off comment in the issue plus an ADR for the decision. The gate
   sits before labeling: tickets are cut from a spec only after it has
   passed. A ticket then earns `ready-for-agent` on the standard two
   conditions — blockers resolved + acceptance criteria defined. No label,
   no work.
7. **What Build reads, in order** (forward contract to the next stage): (1)
   `gh issue view <n> --comments` (the ticket, a child issue per ADR 0002),
   (2) follow the ticket body's spec-path reference (or its parent's
   `intent/<parent-n>-<slug>/`) to the spec; then the `intent.md` for the
   why, (3) every ADR touching the area, (4) root
   `CONTEXT.md`, (5) only then the code. A ticket whose spec or links are
   missing is bounced back to Design, not improvised around.
8. **Greenfield vs brownfield — one workflow, different seeds.** Same
   pipeline, same artifacts, same gates. Greenfield seeds the spec from the
   brief or PRD against SYSTEM-INTENT.md, and its design concerns are mostly
   new seams; brownfield seeds it from the diagnosis, retro finding, or
   transcript, and its design must first read the existing code and ADRs it
   touches, preferring existing seams over new ones. The read order above is
   identical — in brownfield, step (5) simply has more to say.

## Build — agents execute against the tracker

Formalized across issues #2/#3; this section is the contract every host runs,
whatever the harness. The frontier is the tracker:
`gh issue list --label ready-for-agent`, blockers closed.

1. **One ticket per agent session.** A fresh session (any harness — pi, Claude
   Code, Codex) picks one `ready-for-agent` ticket, reads it in the Design §7
   order (ticket → spec → ADRs → `CONTEXT.md` → code), and works nothing else.
2. **Test-first, lean.** Red-green slices; stdlib first; shortest working diff;
   no speculative abstractions. Every test guards behavior no other test covers.
3. **ADRs during Build.** A decision that meets the ADR bar gets
   `docs/adr/NNNN-slug.md` in the same change — committed and pushed
   immediately. Workers cite the ADRs their ticket names.
4. **`plan.md` is Build preparation.** Written after Design, it sequences
   tickets and ADRs into execution order; it is an input to Build, not an
   artifact Build owes.
5. **Proof over claim.** Closing a ticket requires running its acceptance
   criteria and pasting the commands + output into the issue. Failures reopen
   the ticket with the failing command.
6. **Bounce, don't improvise.** A ticket whose spec, ADR, or links are missing
   goes back to Design with a comment saying what's missing — never worked
   around.

**Orchestration is optional and host-specific.** A single session can work the
frontier serially. Parallel builds use whatever the host provides (herdr panes
under pi, headless workers under Claude Code, etc.) under the same
host-neutral rules — orchestrator never writes code, one ticket per worker,
QC + adversarial review before blessing, workers end with a `HANDOFF:` ping,
two consecutive QC failures halt the chain. Those rules live in the
`factory-orchestrator` skill; the hosts change, the contract doesn't.

## Test — one command, fail-first, protected checks

Formalized in issue [#9](https://github.com/smcozart/cozyharness/issues/9).
Build §5 stays; Test adds the repo's own standing rules to every close. The
command is the contract, not any harness hook.

1. **One command is the gate.** `tests/validate.sh [<range>]` prints one
   `ok: <check>` / `FAIL: <check> — <why>` line per check, then
   `N ok, M failed`; non-zero exit means "not healthy." Closing a ticket
   pastes that run (full output + exit code) next to the acceptance-criteria
   output, passing the ticket's range explicitly (e.g. `origin/main..HEAD`) —
   for a bug/defect fix, plus the fail-first pair (red on the bad version,
   then green). A close missing any of the run, the acceptance output, or
   the pair (for fixes) is reopened, same as a failed acceptance criterion.
2. **Fail-first.** A bug/defect fix pastes the pair: the check red on the bad
   version for the expected reason, then green on the fix. A new static check
   is admitted only with a witness — a historic sha it fails on, or a one-line
   mutation that makes it fail — pasted once when the check lands.
3. **Witnesses are runnable.** `tests/validate.sh --witness` replays every
   witness through the same check functions (bad sha / mutated tree → FAIL,
   good sha → ok). A check whose witness stops failing is a broken check.
   Needs full history (`git fetch --unshallow` on a shallow clone).
4. **Protection rule.** A diff that removes, narrows, or reorders a check
   away from the path it guards — or that removes or narrows content a
   negative check guards (an absence check passes vacuously once its target
   wording is deleted), in `tests/` or anywhere else — is rejected in review
   unless it cites the issue that retires the rule. Whoever fixes a checking
   surface does not loosen the check that measures it in the same diff.
5. **Tests are not evals.** `tests/validate.sh` checks artifacts (a file says
   X, a commit touches Y) — deterministic, offline, bash + git + python3
   stdlib. Findings with no textual footprint stay in the eval ledger (#8);
   the eval harness waits on #1, as does CI wiring — the exit code is
   CI-ready.

The check list lives in the `## Commands` block of `AGENTS.md`; the
`agents-commands` check verifies the token set against `--list` (prose and
grouping around the names are not verified).

## Stage-by-stage map

| Stage | Skill | When / where |
|---|---|---|
| Capture the intent | issue + `intent/<n>-<slug>/intent.md` | First, right after the issue exists (see **Plan — issue-first intake** above). |
| Elicit requirements | `/to-questionnaire` | New feature with unknowns. Converts vague asks into answerable questions. |
| Write the spec | `/to-spec` | After questionnaire. Spec lives at `intent/<n>-<slug>/spec.md`, referenced from the issue by path (see **Design** above). Overrides to the vendored skill: write the spec to that path, NOT into the issue body (ADR 0001), and do NOT apply `ready-for-agent` at spec time — the approval gate comes first. |
| Break into tickets | `/to-tickets` | After spec. Tracer-bullet vertical slices; blocking edges declared per ticket (GitHub native blocking links). Never horizontal layers. |
| Groom the queue | `/triage` | Continuous. State machine of triage roles → issues end as agent-ready briefs labeled `ready-for-agent`. AI-generated comments carry the AI-triage disclaimer. |
| Stress-test thinking | `/grilling` (or `/grill-me`, `/grill-with-docs`) | Before accepting a spec, an architecture, or an agent's plan. Cheap insurance; use liberally at decision points. |
| Implement | `/implement` | Per ticket, one ticket per session. Test-first (red-green slices). Lean: stdlib first, shortest working diff. |
| Test discipline | `/tdd` | Default mode inside implement. Every test justifies itself — guards behavior no other test covers. |
| Debugging | `/diagnosing-bugs` | When something is broken/slow, not during planned work. |
| Review | `/code-review` | After each diff (or each batch). Two axes: standards + spec. |
| Adversarial review | `adversary` subagent (pi) | Mandatory on agent-produced diffs. Breaks the author-boss bias loop. Claude equivalent: a second review pass with "assume this is wrong" instructions. |
| Record decisions | `domain-modeling` | ADR bar: hard to reverse, surprising without context, or a real trade-off. One paragraph, `docs/adr/NNNN-slug.md`, **commit and push** — an unpushed ADR is invisible. Visible in code ⇒ no ADR. |
| Shared vocabulary | `CONTEXT.md` via `domain-modeling` | Update when terminology shifts; consumers read it before issues. |
| Milestone retro | `/retro` | At milestones or when a failure pattern repeats. Feed findings into ADRs or process edits. |
| Session end | `/handoff` | Compact conversation → handoff doc for the next session. References artifacts by path; never duplicates them. |

## Orchestration layer (multi-agent builds)

**`factory-orchestrator` skill + a host worker mechanism** — when tickets are
parallelizable and you want workers, not a single session. The skill's rules
are host-neutral; the mechanics below use herdr under pi as the reference
host (swap in your host's equivalent — headless Claude Code workers, Codex
sessions — keeping the same contract). Key rules (full detail in the skill):

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
   commits — the tracker and the remote are the only state.

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
