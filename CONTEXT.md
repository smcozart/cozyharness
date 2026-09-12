# The Harness

The Harness is an AI-native software development process: humans stay above the
loop (instigating, directing, governing) while agents take the center. This
file is the shared vocabulary; every issue, spec, and ADR uses these terms.

## Language

**Harness**:
The process itself — the six-phase loop (Plan → Design → Build → Test → Deploy
→ Maintain) and its contracts — as packaged in this repo. Not any one tool.
_Avoid_: framework, platform, pipeline (the pipeline is only the phase order)

**intent**:
The written, human-approved "why" behind a unit of work. Two levels exist:
SYSTEM-INTENT and work-item intent. No approved intent, no work.
_Avoid_: ticket description, prompt, requirements doc

**work-item intent**:
The intent for one issue, at `intent/<issue-number>-<slug>/intent.md`. States
problem, desired outcome, scope, non-goals, acceptance criteria.
_Avoid_: brief, story, epic

**SYSTEM-INTENT**:
The system's enduring purpose at repo root (`SYSTEM-INTENT.md`). Every
work-item intent is checked against it; conflicts amend it or rewrite the
work-item intent.
_Avoid_: vision doc, charter

**tracker**:
GitHub Issues — the system of record for all work. The issue number is the
**join key** tying together intent, spec, branch, PR, run, and pasted proof.
For ticketed work: branch, PR, and proof join on the ticket (child) issue
number; intent and spec join on the parent design issue number.
_Avoid_: backlog, TODO list, board

**spec.md**:
The Design artifact for one work item, at
`intent/<issue-number>-<slug>/spec.md` (sibling of the intent). States
requirements, design concerns, constraints, and open questions. Linked by
issue number, never copied into the issue body.
_Avoid_: design doc, RFC, plan

**plan.md**:
An execution sequencing for Build (ticket order against blocking edges),
written after Design. Belongs to Build preparation, never to Plan.
_Avoid_: spec, intent

**ADR**:
Architecture decision record in `docs/adr/NNNN-slug.md`. Written only when a
decision is hard to reverse, surprising without context, or a real
trade-off; pushed immediately.
_Avoid_: decision log entry, meeting note

**Design**:
The phase that turns an approved intent into a spec, ADRs, and ticketed
issues. Ends at the approval gate.
_Avoid_: planning (Plan is the intake phase), architecture (only part of it)

**Build**:
The phase where agents execute one ticket per session against the tracker,
test-first, citing ADRs.
_Avoid_: implementation (too loose — Build includes its proof obligations)

**gate**:
A recorded human decision that lets work cross a phase boundary. The Design
gate is approval of the spec; the Test gate is pasted verification output.
Triage is not a gate — it is a label state machine that ends at
`ready-for-agent`.
_Avoid_: sign-off (only the high-risk variant), approval (the act, not the
record)
