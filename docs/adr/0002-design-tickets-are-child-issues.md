# Design tickets are child issues of the design issue, with native blocking edges

A spec breaks into implementation tickets as GitHub **sub-issues of the design
issue** (the parent that carried the intent through Plan), not as flat
unrelated issues and not as task-list checkboxes inside one mega-issue.
Sub-issues give the parent/child relationship a UI-visible, API-addressable
home; each child is a full issue with its own labels, acceptance criteria, and
closing proof. Blocking between children uses GitHub's native issue
dependencies (`blocked_by`), falling back to a `Blocked by: #n` line where
dependencies aren't enabled (mechanics: `docs/agents/issue-tracker.md`). The
parent closes only when every child is closed. The alternative — one issue
with a task list — was rejected because checkboxes can't carry labels, edges,
assignees, or proof; flat issues were rejected because the parent link is what
lets an agent walk from a ticket back to the spec and intent. Where
sub-issues aren't enabled, the fallback is `Part of #<parent>` at the top of
each child body plus a task list in the parent.
