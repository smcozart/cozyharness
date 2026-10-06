---
name: new-project
description: >
  Start a brand-new app repo under the engineering workflow: scaffold the files
  every plugin skill reads, create the GitHub repo with its labels and a
  protected main, run the new repo's gate, then hand off to
  `intent-conversation` for the system intent. Use when the developer says
  "start a new project", "new app", "set up this repo for the workflow",
  "bootstrap this project". Never in a repo that already has `AGENTS.md`,
  `STATUS.md` and an `origin` remote.
---

# New project

One request turns a folder into a repo the whole loop can run in. The
developer sees at most one question, never a template or a file list.

**Not in a repo that is already set up.** If the folder has `AGENTS.md`,
`STATUS.md` and an `origin` remote, reply with exactly this line, nothing
else, and stop:

> This repo is already set up for the workflow — say "catch me up" (`cmu`) to see where it stands.

Without `origin`, an earlier run stopped part way (a dry run, a failed
`gh repo create`, a network error): run the moves as written. The scaffold
skips every file, the commit is skipped when nothing is staged, and the run
continues at Move 4 step 1.

**Never put the developer's words on a command line.** Owner and name come
from `gh` output and the folder name, checked by the scaffold; visibility maps
to a fixed flag. Nothing they typed reaches the shell.

**Dry run.** When the developer asks for a dry run, run every move up to and
including the local commit, skip the GitHub moves of Move 4 (repo, labels,
ruleset, required check), and say in one line which you skipped. Move 1's
read-only `gh` lookups still run: the owner comes from them.

---

## Move 1 — Ground (read-only)

Run, and change nothing:

```bash
pwd -P
ls -A
git rev-parse --show-toplevel 2>/dev/null
git branch --show-current 2>/dev/null; git rev-parse -q --verify HEAD
git remote get-url origin 2>/dev/null
gh api user --jq .login
gh api user/orgs --jq '.[].login'
```

Stop with one line, and change nothing, when:

- the toplevel exists and is not `pwd -P`: the folder is inside another repo,
  and a commit or push here would land in that repo. Name the enclosing repo
  and ask for a folder of its own.
- `HEAD` has commits and the branch is not `main`: name the branch. The
  ruleset, the gate's push trigger and the required check all name `main`.
- `gh api user` fails: `gh` is offline or not logged in (`gh auth status`).

When `origin` exists, owner and name are the origin's repo, not the login
and the folder: `gh repo view --json owner,name --jq '.owner.login + "/" + .name'`.
If that fails, `origin` is not a GitHub repo you can reach; say so and stop.

Find the scaffold script: `<directory of this SKILL.md>/../../templates/new-project/scaffold.sh`.
In cozyharness's own `.claude/skills/` copy that path does not exist; there,
use `plugin/templates/new-project/scaffold.sh` from the repo root. If neither
exists, say so in one line and stop.

Without `origin`, the repo name is the folder's name. The scaffold accepts
only `A-Z a-z 0-9 . _ -`. If the folder name has other characters, propose
your own name — the folder name with each of them replaced by `-` — in the
one question. The developer accepts or refuses it; on a refusal, stop. A name
they type is never used.

## Move 2 — Ask (at most one question)

Skip this move when `origin` exists. Defaults: owner = the `gh api user`
login, visibility = private.

Ask only when `gh api user/orgs` lists an org, or the name needs your
proposal: one question that carries everything, with the defaults named:

> Create `<login>/<name>` as a private repo — or under `<org>`, or public?

The owner you use is the exact string from the `gh` output that the answer
names, never the developer's typed text. With no orgs and a valid name, ask
nothing.

## Move 3 — Scaffold

```bash
git rev-parse --show-toplevel >/dev/null 2>&1 || git init -b main
git rev-parse -q --verify HEAD >/dev/null || git symbolic-ref HEAD refs/heads/main
bash <scaffold.sh> . --owner <owner> --name <name> >"${TMPDIR:-/tmp}/new-project-scaffold.txt"; echo "scaffold exit $?"
cat "${TMPDIR:-/tmp}/new-project-scaffold.txt"
```

The second line names an unborn branch `main` (a `git init` whose default is
`master`). A non-zero scaffold exit: report its output and stop; commit
nothing. Otherwise the script has copied the templates, never overwriting a
file (`skip: <path>`), and printed `wrote: <path>` for each new one. Report
in one line how many it wrote, and name every `skip:`. Never edit a skipped
file to make it fit.

## Move 4 — Commit, then GitHub

Commit every scaffold path, the skipped ones too — CI checks the commit, not
this folder:

```bash
git add $(sed -nE 's/^(wrote|skip): //p' "${TMPDIR:-/tmp}/new-project-scaffold.txt")
git diff --cached --quiet || git commit -m "Start the repo under the engineering workflow"
```

Dry run: stop the move here. Otherwise, in order, every command against
`<owner>/<name>`:

1. **Repo and push.** `gh repo create <owner>/<name> --private --source . --push`
   (`--public` when chosen). When `origin` exists, skip the create and run
   `git push -u origin main`.
2. **Labels** (create only the missing ones):

   ```bash
   have=$(gh label list -R <owner>/<name> --limit 200 --json name --jq '.[].name')
   for l in needs-triage needs-info ready-for-agent ready-for-human wontfix ticket flagged-risk; do
     grep -qx "$l" <<<"$have" || gh label create "$l" -R <owner>/<name>
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

4. **Required check**, after the first CI run on `main` (an empty list means
   the run has not started yet; list again a few times — if none appears, the
   policy stays fail-closed: say so and skip the PUT):

   ```bash
   gh run watch -R <owner>/<name> "$(gh run list -R <owner>/<name> --branch main --limit 1 --json databaseId --jq '.[0].databaseId')" --exit-status
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

Run the gate on a clean clone, so it checks what was committed:

```bash
d=$(mktemp -d) && git clone -q . "$d/c" && (cd "$d/c" && bash tests/validate.sh; bash tests/validate.sh --witness | tail -1)
```

Paste both outputs, and the last ruleset read-back (or "dry run: no
ruleset"). A failing gate is reported as failing, with its output; do not
hand off over it.

## Move 6 — Hand off

One line, then stop: "Set up — tell me what the app is for." The answer
starts `intent-conversation` Move 1: `SYSTEM-INTENT.md` does not exist yet,
and that skill writes it.
