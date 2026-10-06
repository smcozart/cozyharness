---
name: new-project
description: >
  Start a brand-new app repo under the engineering workflow, from an empty
  folder: scaffold the files every plugin skill reads, create the GitHub repo
  with its labels and a protected main, run the new repo's gate, then hand off
  to `intent-conversation` for the system intent. Also finishes its own stopped
  run (a dry run, or a failed GitHub step) in the same folder. Use when the
  developer says "start a new project", "new app" or "bootstrap this project"
  in an empty folder. Never for a repo that is already set up, and never for an
  existing repo or a folder with other content.
---

# New project

One request turns an empty folder into a repo the whole loop can run in. The
developer sees at most one question, never a template or a file list.

**Never put the developer's words on a command line.** Owner and name come
from `gh` output, the origin URL and the folder name, checked against
`A-Z a-z 0-9 . _ -`; visibility maps to a fixed flag. Nothing they typed
reaches the shell.

**Dry run.** When the developer asks for a dry run, run every move up to and
including the local commit, skip the GitHub moves of Move 4 (repo, labels,
ruleset, required check), and say in one line which you skipped. Move 1's
read-only lookups still run: the owner comes from them.

---

## Move 1 — Ground and classify (read-only)

Run, and change nothing:

```bash
pwd -P
ls -A
git rev-parse --show-toplevel 2>/dev/null
git rev-list --count HEAD 2>/dev/null; git log -1 --format=%s 2>/dev/null
git status --porcelain 2>/dev/null
git remote get-url origin 2>/dev/null
git ls-remote --exit-code origin main >/dev/null 2>&1; echo "origin main: $?"
gh api user --jq .login
gh api user/orgs --jq '.[].login'
```

Classify the folder; the first row that matches wins. Every stop is one line
and changes nothing.

| Folder | Route |
|---|---|
| **Enclosing repo:** the toplevel exists and is not `pwd -P` | Stop: name the enclosing repo, and say that `git init` in this folder makes it a repo of its own. |
| **Set up:** `AGENTS.md`, `STATUS.md`, an `origin`, and `main` on it (`origin main: 0`) | Stop with the set-up line below. |
| **This skill's stopped run:** `AGENTS.md` and `STATUS.md`, a clean tree, one commit, subject `Start the repo under the engineering workflow` | Resume: skip Move 3 and the commit, run Move 2 only when there is no `origin`, and continue at Move 4 step 1. |
| **New:** `ls -A` shows nothing or only `.git`, no commits, no `origin` | Full run. |
| **Anything else** | Stop with the not-supported line below. |

Each of these two lines is the whole reply — exactly this text, nothing else:

> This repo is already set up for the workflow — say "catch me up" (`cmu`) to see where it stands.

> This folder already has content — setting up an existing repo is not supported yet.

If `gh api user` fails, `gh` is offline or not logged in (`gh auth status`):
say so in one line and stop.

**Owner and name.** On a resume with an `origin`, parse them from
`git remote get-url origin` (`github.com[:/]<owner>/<name>(.git)?`); accept
only `A-Z a-z 0-9 . _ -` in each, else stop in one line. Otherwise the owner
is the `gh api user` login (or an org, Move 2), and the name is the folder's
name. If the folder name has other characters, propose your own name — the
folder name with each of them replaced by `-` — in the one question. The
developer accepts or refuses it; on a refusal, stop. A name they type is never
used.

Find the scaffold script: `<directory of this SKILL.md>/../../templates/new-project/scaffold.sh`.
In cozyharness's own `.claude/skills/` copy that path does not exist; there,
use `plugin/templates/new-project/scaffold.sh` from the repo root. If neither
exists, say so in one line and stop.

## Move 2 — Ask (at most one question)

Defaults: owner = the `gh api user` login, visibility = private.

Ask only when `gh api user/orgs` lists an org, or the name needs your
proposal: one question that carries everything, with the defaults named:

> Create `<login>/<name>` as a private repo — or under `<org>`, or public?

The owner you use is the exact string from the `gh` output that the answer
names, never the developer's typed text. With no orgs and a valid name, ask
nothing.

## Move 3 — Scaffold (new route only)

```bash
[ -d .git ] || git init -b main
git symbolic-ref HEAD refs/heads/main
out=$(mktemp); echo "scaffold output: $out"
bash <scaffold.sh> . --owner <owner> --name <name> >"$out"; echo "scaffold exit $?"
cat "$out"
```

`git symbolic-ref` names the unborn branch `main` (a `git init` whose default
is `master`). A non-zero scaffold exit: report its output and stop; commit
nothing. Otherwise report in one line how many files it wrote.

## Move 4 — Commit, then GitHub

New route only — commit what the scaffold wrote (`<scaffold output>` is the
path Move 3 printed):

```bash
git add -- $(sed -n 's/^wrote: //p' <scaffold output>); echo "add exit $?"
git commit -m "Start the repo under the engineering workflow"
```

A non-zero `git add` (for example a template path that a global git exclude
ignores): report its output and stop; do not commit.

Dry run: stop the move here. Otherwise, in order, every command against
`<owner>/<name>`. Each step checks the state first, so a resume repeats
nothing that is done:

1. **Repo and push.** If `gh repo view <owner>/<name>` succeeds, skip the
   create: add `origin` when it is missing
   (`git remote add origin https://github.com/<owner>/<name>.git`), then
   `git push -u origin main`. Otherwise:
   `gh repo create <owner>/<name> --private --source . --push` (`--public`
   when chosen).
2. **Labels** (create only the missing ones):

   ```bash
   have=$(gh label list -R <owner>/<name> --limit 200 --json name --jq '.[].name')
   for l in needs-triage needs-info ready-for-agent ready-for-human wontfix ticket flagged-risk; do
     grep -qx "$l" <<<"$have" || gh label create "$l" -R <owner>/<name>
   done
   ```

3. **Ruleset on `main`**, then read it back. Skip the POST when
   `gh api repos/<owner>/<name>/rulesets --jq '.[] | select(.name == "main") | .id'`
   prints an id.

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

   Report a POST error, but decide enforcement on the read-back alone.
   **If the read-back is `[]`** (a private repo on a free plan): say so in one
   line. Add this line to the end of `docs/engineering-workflow.md` and of
   `docs/adr/0001-adopt-engineering-workflow.md`:
   `**Enforcement:** none (rules on main read back empty, <YYYY-MM-DD>) — pre-merge human checkoff until a ruleset is enforced.`
   Commit, `git push`, and skip step 4.

4. **Required check**, only when the read-back lacks
   `required_status_checks`. Wait for the first CI run on `main` (an empty
   list means the run has not started yet; list again a few times — if none
   appears, the policy stays fail-closed: say so and skip the PUT):

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
