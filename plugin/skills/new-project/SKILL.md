---
name: new-project
description: >
  Start a brand-new app repo under the engineering workflow: scaffold the files
  every plugin skill reads, create the GitHub repo with its labels and a
  protected main, run the new repo's gate, then hand off to
  `intent-conversation` for the system intent. Use when the developer says
  "start a new project", "new app", "set up this repo for the workflow",
  "bootstrap this project". Never in a repo that already has `AGENTS.md` and
  `STATUS.md`.
---

# New project

One request turns a folder into a repo the whole loop can run in. The
developer sees at most one question, never a template or a file list.

**Not in a repo that is already set up.** If the folder has both `AGENTS.md`
and `STATUS.md`, say in one line that it is already set up for the workflow,
offer `cmu` ("say 'catch me up' to see where it stands"), and stop.

**Never put the developer's words on a command line.** Owner and name come
from `gh` output and the folder name, checked by the scaffold; visibility maps
to a fixed flag. Nothing they typed reaches the shell.

**Dry run.** When the developer asks for a dry run, run every move up to and
including the local commit, skip the GitHub moves of Move 4 (repo, labels,
ruleset, required check), and say in one line which you skipped. Move 1's
read-only `gh api` lookups still run: the owner comes from them.

---

## Move 1 — Ground (read-only)

Run, and change nothing:

```bash
ls -A
git rev-parse --show-toplevel 2>/dev/null && git branch --show-current
git remote get-url origin 2>/dev/null
gh api user --jq .login
gh api user/orgs --jq '.[].login'
```

Find the scaffold script: `<directory of this SKILL.md>/../../templates/new-project/scaffold.sh`.
In cozyharness's own `.claude/skills/` copy that path does not exist; there,
use `plugin/templates/new-project/scaffold.sh` from the repo root. If neither
exists, say so in one line and stop.

The repo name is the folder's name. The scaffold accepts only
`A-Z a-z 0-9 . _ -`; if the folder name has other characters, propose it with
each of them replaced by `-`, as part of the one question.

## Move 2 — Ask (at most one question)

Defaults: owner = the `gh api user` login, visibility = private.

Ask only when `gh api user/orgs` lists an org (or the name needs a fix): one
question that carries owner and visibility together, with the defaults named:

> Create `<login>/<name>` as a private repo — or under `<org>`, or public?

The owner you use is the exact string from the `gh` output that the answer
names, never the developer's typed text. With no orgs and a valid name, ask
nothing.

## Move 3 — Scaffold

```bash
git rev-parse --show-toplevel 2>/dev/null || git init -b main
bash <scaffold.sh> . --owner <owner> --name <name> | tee "${TMPDIR:-/tmp}/new-project-scaffold.txt"
```

The script copies the templates, never overwrites a file (`skip: <path>`),
and prints `wrote: <path>` for each new one. Report in one line how many it
wrote, and name every `skip:`. Never edit a skipped file to make it fit.

## Move 4 — Commit, then GitHub

Commit only what the scaffold wrote:

```bash
git add $(sed -n 's/^wrote: //p' "${TMPDIR:-/tmp}/new-project-scaffold.txt")
git commit -m "Start the repo under the engineering workflow"
```

Dry run: stop the move here. Otherwise, in order:

1. **Repo and push.** `gh repo create <owner>/<name> --private --source . --push`
   (`--public` when chosen). When Move 1 found an `origin`, skip the create and
   run `git push -u origin main`.
2. **Labels** (create only the missing ones):

   ```bash
   have=$(gh label list --limit 200 --json name --jq '.[].name')
   for l in needs-triage needs-info ready-for-agent ready-for-human wontfix ticket flagged-risk; do
     grep -qx "$l" <<<"$have" || gh label create "$l"
   done
   ```

3. **Ruleset on `main`**, then read it back:

   ```bash
   gh api repos/<owner>/<name>/rulesets -X POST --input - <<'JSON'
   {"name": "main", "target": "branch", "enforcement": "active",
    "conditions": {"ref_name": {"include": ["refs/heads/main"], "exclude": []}},
    "rules": [{"type": "deletion"}, {"type": "non_fast_forward"},
      {"type": "pull_request", "parameters": {"required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false, "require_code_owner_review": false,
        "require_last_push_approval": false, "required_review_thread_resolution": false}}]}
   JSON
   gh api repos/<owner>/<name>/rules/branches/main --jq '[.[].type]'
   ```

   **If the POST fails or the read-back is `[]`** (a private repo on a free
   plan): say so in one line. Add this line to the end of
   `docs/engineering-workflow.md` and of
   `docs/adr/0001-adopt-engineering-workflow.md`:
   `**Enforcement:** none (rules on main read back empty, <YYYY-MM-DD>) — pre-merge human checkoff until a ruleset is enforced.`
   Commit, `git push`, and skip step 4.

4. **Required check**, after the first CI run on `main` (if the list is empty,
   the run has not started yet; list again):

   ```bash
   gh run watch "$(gh run list --branch main --limit 1 --json databaseId --jq '.[0].databaseId')" --exit-status
   id=$(gh api repos/<owner>/<name>/rulesets --jq '.[] | select(.name == "main") | .id')
   gh api repos/<owner>/<name>/rulesets/$id -X PUT --input - <<'JSON'
   {"name": "main", "target": "branch", "enforcement": "active",
    "conditions": {"ref_name": {"include": ["refs/heads/main"], "exclude": []}},
    "rules": [{"type": "deletion"}, {"type": "non_fast_forward"},
      {"type": "pull_request", "parameters": {"required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false, "require_code_owner_review": false,
        "require_last_push_approval": false, "required_review_thread_resolution": false}},
      {"type": "required_status_checks", "parameters": {"strict_required_status_checks_policy": false,
        "required_status_checks": [{"context": "gate"}]}}]}
   JSON
   gh api repos/<owner>/<name>/rules/branches/main --jq '[.[].type]'
   ```

   The PUT replaces the rule list, so it resends the three rules from step 3.
   The read-back must list `required_status_checks`; if it does not, the
   policy is fail-closed — say so in one line.

## Move 5 — Verify

```bash
bash tests/validate.sh
bash tests/validate.sh --witness | tail -1
```

Paste both outputs, and the last ruleset read-back (or "dry run: no
ruleset"). A failing gate is reported as failing, with its output; do not
hand off over it.

## Move 6 — Hand off

One line, then stop: "Set up — tell me what the app is for." The answer
starts `intent-conversation` Move 1: `SYSTEM-INTENT.md` does not exist yet,
and that skill writes it.
