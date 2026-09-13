# Handoff: CozyHarness — session pickup (13 Sep 2026)

**From:** maintain + operator-orchestrator session · **For:** a fresh session
continuing work on the Harness. **Repo:** `smcozart/cozyharness` (branch
`main`, clean you up at `327478c`).
**Start here:** in the repo, read `STATUS.md` first — it is the live board
snapshot. THIS FILE is the context-under-floor-of-the session; the repo and
tracker are the truth.

---

## What this system is, in one paragraph

The Harness is a portable, host-neutral AI-native SDLC process: humans
instigate/direct/govern, agents execute, all six stages are codified as
contracts in the repo. Works on **pi** (AGENTS.md, `.agents/skills/`,
`.pi/`) and **Claude Code** (CLAUDE.md, plugin, `.claude/skills/`). GitHub
Issues is the tracker and the join key. The proof gate is one command:
`tests/validate.sh` (and `--witness`). Everything versioned, every close
needs pasted proof, hard-to-reverse decisions become ADRs.

## Read first (in this order) — the fresh-session entrance ramp

`STATUS.md` (board) → `AGENTS.md` / `CLAUDE.md` (actions/contracts) →
`SYSTEM-INTENT.md` → `CONTEXT.md` (vocabulary) →
`docs/engineering-workflow.md` (canonical six-stage process) → `REVIEW.md`
(review/adversary policy) → `docs/training/onboarding-runbook.md` (standing
up machines + a project). Model policy: auto-routed preferred; pin a smart
model only if QC warrants it (Kimi-k3 for the adversary pass). pi can't
drive opus-5 (mid-convo reasoning-effort 400) — opus-4.8 works as the pin.

### Suggested skills for the next session
- `engineering-workflow` (core process; the six-phase contract).
- `factory-orchestrator` (multi-agent build loop; the orchestrator model).
- `domain-modeling` (vocabulary + ADRs into CONTEXT.md).
- `tdd` / `implement` (per ticket), `code-review` + the adversary subagent
  (per-merge-gate).
- `handoff` (compact from THIS to the next).
- (On Claude: `/setup-matt-pocock-skills` scaffolded once; hooks advisory.)

---

## Where the board is (verified state)

**Done with proof:** the six phases — Plan #2 · Design #3 · Build #4 ·
Test #9 · Deploy #12 · Maintain #15 — plus **Claude host parity #19/#20**
and the **hooks-core landing #21/#22** (`a7f7523`). Milestone tag
`v1-harness-complete`.

**Open frontier:**
- #1 — Hooks parent (for the pi event-advisor intent / later per-host work).
- #8 — Eval ledger (text-only corpus; runner needs #1).
- #18 — Two carried LOW findings (owner: operator; deferred).
- #23 — Hooks envelope: pre-push checks HEAD, not the pushed refs (owner:
  operator; resolve with a spec amendment).

**Queued next (explicitly agreed, not started):**
- **Claude-host pipeline pilot** — one real ticket through the full
  pipeline with **Claude Code orchestrator + workers** (drive with
  `claude -p` headless in tmux, or `herdr --kind claude`). This is the
  immediately natural next intake.

## Operating manual synopsis (the parts that actually matter)

1. **Gates are human and never pre-empted.** Issue-driven flow
   (issue → intent → spec → plan → tickets → build). Intents/specs land in
   `intent/<issue>-<slug>/<intent|spec>.md` with Status draft→approved at
   the operator's approval commit. `ready-for-agent` = blockers resolved +
   acceptance defined; labeled by the gate only. Insert into GitHub issues
   (sub-issues and blocking edges).
4. **`--no-verify` / un-bootstrapped clones bypass the hooks — by design.**
   This is a documented local guardrail, not a server; a green suite is
   necessary, not sufficient. The human gate stays the authority.

3. **The hooks are live now (local, installed by `bootstrap.sh`):**
   pre-commit enforces the trio sync rule; pre-push runs validate (silent
   on green). Local and bypassable — honest, not faked. They are git-seam
   and work on any host (incl. pi once bootstrapped). There is no CI or
   branch protection on this repo — that is a real limit (see #8, #23).
4. **Un-bootstrapped clones and `--no-verify` bypass the hooks — by design.**
   This is a documented local guardrail, not a server; a green suite is
   necessary, not sufficient. The human gate stays the authority.
5. **Model ops.** Auto-priced for workers (set `ORCH_PANE_ID`, require the
   `HANDOFF:` ping); ad-hoc pin only for a chosen pass: Kimi-k3 for
   adversarial review, opus-4.8 as worker pin, opus-5 currently undrivable
   from pi (reasoning-effort 400). If two reviewer models disagree, loop them
   to agreement before blessing a result.

## Environment / replication

- Fresh clone: `./bootstrap.sh` + `gh auth` → done (logs, hooks, skills).
- Proof: `tests/validate.sh` (suite suite runs offline, bash+git+py3).
- The harness travels to a NEW project via §4.5 of
  `docs/training/onboarding-runbook.md` — copy the scaffold, keep YOUR OWN
  SYSTEM-INTENT/CONTEXT/STATUS. Hooks travel too.

## Sensitive-material note

Nothing sensitive (no keys, no PII) is in this handoff or the repo-wired
artifacts. Private = the repo + the Issues tracker + the `gh` credential on
this machine. The RAG project work happens elsewhere (work machine / Azure).

---

## Jump back in (the short version)

1. `gh issue list --state open` → pick the live frontier or the queued
   Claude **pilot**.
2. Read `STATUS.md` + the fresh-session bundle above.
3. Run the gates with you, operator; never singly self-approve.
4. When work lands, close with the merge-gate proof pasted.

**Good to continue on the Harness from exactly here.**