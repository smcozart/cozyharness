#!/usr/bin/env bash
# The Test gate: one command, one exit code, one line per check.
# Spec: intent/9-test-stage/spec.md (check tables are the requirement, verbatim).
#
#   tests/validate.sh [<range>]   run every check (sync-rule over <range>, else dirty tree, else HEAD~1..HEAD)
#   tests/validate.sh --list      print check names, one per line
#   tests/validate.sh --witness   run every fail-first witness (needs full history)
#   tests/validate.sh --lane [<range>]  classify the diff's review lane (T0/T1/T2) from what git sees (ADR 0003)
#
# Requires: bash, git, grep/awk, python3 (stdlib). Offline. Never mutates the
# working tree — witness copies are `git worktree add` under $TMPDIR, trap-removed.
# Witnesses run against HEAD worktrees (committed state), not the dirty tree —
# deliberate: a witness proves the check's logic, the default run proves the tree.
set -uo pipefail
cd "$(git -C "$(dirname "$0")" rev-parse --show-toplevel)" || exit 2

FO=plugin/skills/factory-orchestrator/SKILL.md
DOC=docs/engineering-workflow.md
SK=plugin/skills/engineering-workflow/SKILL.md
CHECKS="sync-rule stage-parity intent-layout adr-numbering adr-refs hooks-json skill-frontmatter skill-copies agents-commands t1-trust-wording t1-log-clobber t1-spawn-session t3-label-drift t3-precedence"

# ---------- lane classifier (Deploy: review effort follows the lane; ADR 0003) ----------
# A classifier, not a check: it prints one `lane:` line to paste beside the gate run and never fails.
# It sees files, not meaning — the agent still confirms "earns no ADR" and "not speculative", and may
# only ESCALATE the printed lane. Consumers extend LANE_PROTECTED with their own suite surfaces
# (src/, infrastructure/, security paths); LANE_BOARD is the file a fresh session reads first.
LANE_PROTECTED='^(tests/|\.githooks/|\.github/|plugin/|\.agents/|\.claude/|\.claude-plugin/|\.pi/|\.gitignore$|\.gitattributes$|docs/adr/|docs/agents/|intent/|AGENTS\.md$|CLAUDE\.md$|CONTRIBUTING\.md$|REVIEW\.md$|CONTEXT\.md$|SYSTEM-INTENT\.md$|README\.md$|docs/engineering-workflow\.md$|bootstrap\.sh$|skills-lock\.json$)'
LANE_BOARD='^STATUS\.md$'
LANE_MAX_FILES=2; LANE_MAX_LINES=60
lane_of() {  # lane_of <root> <range> -> sets lane (T0|T1|T2) and lane_why; rc 2 only if git diff fails
  local r=$1 range=$2 files n prot lines
  files=$(git -C "$r" diff --name-only "$range" 2>/dev/null) || { lane=T2; lane_why="git diff $range failed — heavy by default"; return 2; }
  [ -n "$files" ] && { n=$(grep -c . <<<"$files"); } || { lane=T0; lane_why="empty range"; return 0; }
  prot=$(grep -E "$LANE_PROTECTED" <<<"$files" | tr '\n' ' ')
  lines=$(git -C "$r" diff --numstat "$range" | awk '{a+=$1; d+=$2} END{print a+d+0}')
  if   [ -n "$prot" ];                       then lane=T2; lane_why="protected surface: ${prot% }"
  elif [ "$n" -gt "$LANE_MAX_FILES" ];        then lane=T2; lane_why="$n files (>$LANE_MAX_FILES)"
  elif [ "$lines" -gt "$LANE_MAX_LINES" ];    then lane=T2; lane_why="$lines changed lines (>$LANE_MAX_LINES)"
  elif grep -qE "$LANE_BOARD" <<<"$files";   then lane=T1; lane_why="touches the board ($(grep -E "$LANE_BOARD" <<<"$files" | tr '\n' ' '| sed 's/ $//')) — the first file a session reads"
  elif ! grep -qvE '\.md$' <<<"$files";      then lane=T0; lane_why="$n file(s), docs-only, $lines lines, no protected surface"
  else                                          lane=T1; lane_why="$n file(s), $lines changed lines, no protected surface"
  fi
}
lane_run() {  # lane_run [<range>] -> prints the lane line (+ the agent's two clauses); always exit 0
  local range=${1:-}
  if [ -z "$range" ]; then if ! git diff --quiet HEAD 2>/dev/null; then range=HEAD; else range=HEAD~1..HEAD; fi; fi
  lane_of . "$range"
  case $lane in T0) echo "lane: T0 trivial — $lane_why ($range)";; T1) echo "lane: T1 light — $lane_why ($range)";; *) echo "lane: T2 heavy — $lane_why ($range)";; esac
  [ "$lane" = T2 ] || echo "agent confirms before closing at $lane: earns no ADR; not speculative (no public contract, no multi-edge blocker). Either fails → T2. Escalate only."
}

fail=0; why=""
list_checks() { printf '%s\n' $CHECKS; }

# ---------- static half: check_<name> <root> (sync-rule: <range>) ----------
check_sync_rule() {  # $1 = git range
  local files
  files=$(git diff --name-only "$1" 2>/dev/null) || { why="git diff $1 failed (bad range or shallow clone; git fetch --unshallow)"; return 1; }
  grep -qxE "$DOC|$SK" <<<"$files" || return 0
  local n; n=$(grep -cxE "$DOC|$SK|README.md" <<<"$files")
  [ "$n" -eq 3 ] || { why="$1 touches $DOC/SKILL.md; expected 3 of {doc,SKILL.md,README.md}, found $n"; return 1; }
}

check_stage_parity() {
  local r=$1 d s m
  for f in "$DOC" "$SK" README.md; do [ -f "$r/$f" ] || { why="$f missing"; return 1; }; done
  d=$(grep -cE '^## (Plan|Design|Build|Test|Deploy|Maintain)\b' "$r/$DOC")
  s=$(grep -cE '^## (Plan|Design|Build|Test|Deploy|Maintain)\b' "$r/$SK")
  m=$(grep -cE '^(Plan|Design|Build|Test|Deploy|Maintain) (─)+►' "$r/README.md")
  [ "$d$s$m" = 666 ] || { why="expected 6 stage headings each; found doc=$d SKILL.md=$s README=$m"; return 1; }
  d=$(grep -oE '^## (Plan|Design|Build|Test|Deploy|Maintain)\b' "$r/$DOC" | grep -oE '(Plan|Design|Build|Test|Deploy|Maintain)' | sort -u | wc -l | tr -d " ")
  s=$(grep -oE '^## (Plan|Design|Build|Test|Deploy|Maintain)\b' "$r/$SK" | grep -oE '(Plan|Design|Build|Test|Deploy|Maintain)' | sort -u | wc -l | tr -d " ")
  m=$(grep -oE '^(Plan|Design|Build|Test|Deploy|Maintain) (─)+►' "$r/README.md" | grep -oE '(Plan|Design|Build|Test|Deploy|Maintain)' | sort -u | wc -l | tr -d " ")
  [ "$d$s$m" = 666 ] || { why="expected 6 distinct stage names each; found doc=$d SKILL.md=$s README=$m"; return 1; }
}

check_intent_layout() {
  local r=$1 d n slug got
  for d in "$r"/intent/*/; do
    d=${d%/}; slug=${d##*/}
    [[ $slug =~ ^[0-9]+-[a-z0-9-]+$ ]] || { why="intent/$slug: bad dir name"; return 1; }
    n=${slug%%-*}
    [ -f "$d/intent.md" ] || { why="intent/$slug/intent.md missing"; return 1; }
    got=$(grep -oE '^\*\*Issue:\*\* #[0-9]+' "$d/intent.md" | head -1 | grep -oE '[0-9]+$')
    [ "$got" = "$n" ] || { why="intent/$slug/intent.md: expected **Issue:** #$n, found #${got:-none}"; return 1; }
    [ -f "$d/spec.md" ] || continue
    got=$(grep -oE '^\*\*Issue:\*\* #[0-9]+' "$d/spec.md" | head -1 | grep -oE '[0-9]+$')
    [ "$got" = "$n" ] || { why="intent/$slug/spec.md: expected **Issue:** #$n, found #${got:-none}"; return 1; }
    grep -qF "**Intent:** \`intent/$slug/intent.md\`" "$d/spec.md" \
      || { why="intent/$slug/spec.md: **Intent:** does not point at intent/$slug/intent.md"; return 1; }
  done
}

check_adr_numbering() {
  local r=$1 f b i=0 want
  [ -d "$r/docs/adr" ] && ls "$r"/docs/adr/*.md >/dev/null 2>&1 || { why="docs/adr has no *.md"; return 1; }
  for f in "$r"/docs/adr/*.md; do
    b=${f##*/}; i=$((i+1)); want=$(printf '%04d' "$i")
    [[ $b =~ ^[0-9]{4}-[a-z0-9-]+\.md$ ]] || { why="docs/adr/$b: bad name"; return 1; }
    [ "${b:0:4}" = "$want" ] || { why="docs/adr/$b: expected $want (contiguous 0001..N)"; return 1; }
    grep -q '^\*\*Issue:\*\*' "$f" || { why="docs/adr/$b: no **Issue:** header"; return 1; }
  done
}

check_adr_refs() {
  local r=$1 f bad="" line n
  for f in AGENTS.md CONTRIBUTING.md README.md CONTEXT.md "$DOC"; do [ -f "$r/$f" ] || { why="$f missing"; return 1; }; done
  while IFS= read -r line; do
    n=$(grep -oE '[0-9]{4}' <<<"${line##*:}")
    ls "$r"/docs/adr/"$n"-*.md >/dev/null 2>&1 || bad="$bad ${line%:*}(${line##*:})"
  done < <(cd "$r" && grep -rnoiE 'adr[ -]?[0-9]{4}|docs/adr/[0-9]{4}' AGENTS.md CONTRIBUTING.md README.md CONTEXT.md "$DOC" docs/adr intent plugin)
  [ -z "$bad" ] || { why="no docs/adr/NNNN-*.md for:$bad"; return 1; }
}

check_hooks_json() {
  local f=$1/plugin/hooks/hooks.json
  [ -f "$f" ] || { why="plugin/hooks/hooks.json missing"; return 1; }
  python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert list(d)==["hooks"]; [ (h["type"],h["command"]) for ev in d["hooks"].values() for m in ev for h in m["hooks"] ]' "$f" 2>/dev/null \
    || { why="plugin/hooks/hooks.json: expected sole key hooks + type/command per entry; python3 rejected it"; return 1; }
}

check_skill_frontmatter() {
  local r=$1 f d files
  files=$(git -C "$r" ls-files '*/skills/*/SKILL.md')
  [ -n "$files" ] || { why="git ls-files matched no */skills/*/SKILL.md"; return 1; }
  while IFS= read -r f; do
    d=$(basename "$(dirname "$f")")
    awk -v d="$d" 'NR==1&&$0!="---"{bad=1} NR>1&&!e&&$0=="---"{e=1} NR>1&&!e&&$0=="name: "d{n=1} NR>1&&!e&&/^description: .+/{de=1} END{exit !(e&&n&&de&&!bad)}' "$r/$f" \
      || { why="$f: expected --- / name: $d / description: … / --- frontmatter"; return 1; }
  done <<<"$files"
}

check_skill_copies() {
  cmp -s "$1/$FO" "$1/.agents/skills/factory-orchestrator/SKILL.md" \
    || { why="$FO and .agents/skills/factory-orchestrator/SKILL.md differ (must be byte-identical)"; return 1; }
  cmp -s "$1/$FO" "$1/.claude/skills/factory-orchestrator/SKILL.md" \
    || { why="$FO and .claude/skills/factory-orchestrator/SKILL.md differ (must be byte-identical)"; return 1; }
  cmp -s "$1/$SK" "$1/.claude/skills/engineering-workflow/SKILL.md" \
    || { why="$SK and .claude/skills/engineering-workflow/SKILL.md differ (must be byte-identical)"; return 1; }
}

check_agents_commands() {
  local r=$1 have want
  [ -f "$r/AGENTS.md" ] || { why="AGENTS.md missing"; return 1; }
  have=$(awk '/^## Commands/{c=1;next} /^## /{c=0} c' "$r/AGENTS.md" | grep -oE '`[a-z0-9-]+`' | tr -d '`' | sort -u)
  want=$(list_checks | sort -u)
  [ "$have" = "$want" ] || { why="AGENTS.md ## Commands names != --list; missing:[$(comm -13 <(echo "$have") <(echo "$want") | tr '\n' ' ')] extra:[$(comm -23 <(echo "$have") <(echo "$want") | tr '\n' ' ')]"; return 1; }
}

# ---------- regression half (#8 corpus): check_<name> <file>, never stdin ----------
# t1-trust-wording  FO  bad 7e8a195 ("skips"), da9eb33 (REFUSES)  good 4e9b547
check_t1_trust_wording() {
  grep -q 'trust dialog is SKIPPED' "$1" && ! grep -qw REFUSES "$1" \
    || { why="$1: expected 'trust dialog is SKIPPED' and no REFUSES"; return 1; }
}
# t1-log-clobber  FO  bad da9eb33  good 4e9b547
check_t1_log_clobber() {
  ! grep -qE '>log[[:space:]]' "$1" || { why="$1: bare '>log ' redirect clobbers the shared log"; return 1; }
}
# t1-spawn-session  FO  bad 7e8a195, da9eb33  good 4e9b547
check_t1_spawn_session() {
  grep -qE '^- Spawn:.*--output-format' "$1" || { why="$1: Spawn line does not capture a session id (--output-format)"; return 1; }
}
# t3-label-drift  AGENTS.md  bad 43b63dc  good 92e6a25
check_t3_label_drift() {
  grep -qF 'does NOT apply `ready-for-agent` at spec time' "$1" && ! grep -qF 'never auto-apply labels' "$1" \
    || { why="$1: expected 'does NOT apply \`ready-for-agent\` at spec time' and no 'never auto-apply labels'"; return 1; }
}
# t3-precedence  AGENTS.md  bad 43b63dc  good 92e6a25
check_t3_precedence() {
  grep -qF 'Overrides to the vendored skill:' "$1" || { why="$1: missing 'Overrides to the vendored skill:'"; return 1; }
}

# ---------- runner ----------
verdict() {  # verdict <name> <arg> -> sets v=ok|FAIL and why (no subshell: why must survive)
  local name=$1; shift; why=""; v=FAIL
  if [ -f "$1" ] || [ -d "$1" ] || [ "$name" = sync-rule ]; then
    "check_${name//-/_}" "$@" && v=ok
  else why="$1: file missing"; fi
}
fail_count=0
run() {
  verdict "$@"
  case $v in ok) echo "ok: $1" ;; *) echo "FAIL: $1 — $why"; fail=1; fail_count=$((fail_count+1)) ;; esac
}

default_run() {
  local range=${1:-}
  if [ -z "$range" ]; then
    if ! git diff --quiet HEAD 2>/dev/null; then range=HEAD; else range=HEAD~1..HEAD; fi
  fi
  run sync-rule "$range"
  for c in stage-parity intent-layout adr-numbering adr-refs hooks-json skill-frontmatter skill-copies agents-commands; do run "$c" .; done
  for c in t1-trust-wording t1-log-clobber t1-spawn-session; do run "$c" "$FO"; done
  for c in t3-label-drift t3-precedence; do run "$c" AGENTS.md; done
  local n; n=$(list_checks | wc -l | tr -d ' ')
  echo "$((n - fail_count)) ok, $fail_count failed"
}

# ---------- witness mode ----------
BASE=  # every worktree and temp file lives under one mktemp dir; trap removes it all
cleanup() { for w in "$BASE"/wt-*; do [ -d "$w" ] && git worktree remove --force "$w" >/dev/null 2>&1; done; rm -rf "$BASE"; git worktree prune; }
worktree() {  # worktree <sha> -> sets W (no subshell: a failed add must abort, never a vacuous FAIL row)
  W=$BASE/wt-$1
  git worktree add --detach --quiet "$W" "$1" >/dev/null 2>&1 || { echo "!! cannot check out $1 (git fetch --unshallow?)" >&2; exit 2; }
}
wfail=0; wn=0
expect() {  # expect <ok|FAIL> <label> <check> <arg>
  local want=$1 label=$2 name=$3 arg=$4; wn=$((wn+1))
  verdict "$name" "$arg"
  if [ "$v" = "$want" ]; then echo "witness ok: $name @$label expected $want${why:+ ($why)}"
  else echo "witness FAIL: $name @$label expected $want, got $v${why:+ — $why}"; wfail=1; fi
}
have_sha() { git cat-file -e "$1^{commit}" 2>/dev/null || { echo "witness FAIL: sha $1 not in history (git fetch --unshallow)"; wfail=1; return 1; }; }
showfile() {  # showfile <sha> <path> -> sets T (no subshell: a failed git show must abort, never a vacuous FAIL)
  T=$BASE/$1-${2##*/}
  git show "$1:$2" >"$T" 2>/dev/null || { echo "!! git show $1:$2 failed"; exit 2; }
}
sha_row() { showfile "$2" "$4"; expect "$1" "$2" "$3" "$T"; }  # sha_row <ok|FAIL> <sha> <check> <path>
reset_wt() { git -C "$1" checkout --quiet -- . && git -C "$1" clean -fdq; }

witness_run() {
  [ "$(git rev-parse --is-shallow-repository)" = false ] || { echo "!! shallow clone: run 'git fetch --unshallow' first"; exit 2; }
  BASE=$(mktemp -d "${TMPDIR:-/tmp}/validate.XXXXXX"); trap cleanup EXIT
  for s in a6519a9 571afe4 1b41a31 7e8a195 da9eb33 4e9b547 43b63dc 92e6a25; do have_sha "$s" || exit 2; done

  # sha witnesses — static
  expect FAIL a6519a9 sync-rule 'a6519a9~1..a6519a9'
  expect ok   571afe4 sync-rule '571afe4~1..571afe4'
  worktree 1b41a31; local w=$W
  expect FAIL 1b41a31 stage-parity "$w"
  expect FAIL 1b41a31 adr-refs "$w"

  # mutation witnesses — one-line mutations on a worktree copy of HEAD, reset between rows
  worktree HEAD; local m=$W
  expect ok baseline stage-parity "$m"
  (cd "$m" && python3 -c "p='intent/9-test-stage/intent.md';s=open(p).read().replace('#9','#8');open(p,'w').write(s)")
  expect FAIL mutation intent-layout "$m"; reset_wt "$m"
  : >"$m/docs/adr/0009-x.md"
  expect FAIL mutation adr-numbering "$m"; reset_wt "$m"
  python3 -c "import sys;p=sys.argv[1];s=open(p).read();i=s.rstrip().rfind('}');open(p,'w').write(s[:i]+','+s[i:])" "$m/plugin/hooks/hooks.json"
  expect FAIL mutation hooks-json "$m"; reset_wt "$m"
  (cd "$m" && grep -v '^name:' $FO > t && mv t $FO)
  expect FAIL mutation skill-frontmatter "$m"; reset_wt "$m"
  echo x >> "$m/.agents/skills/factory-orchestrator/SKILL.md"
  expect FAIL mutation skill-copies "$m"; reset_wt "$m"
  echo x >> "$m/.claude/skills/factory-orchestrator/SKILL.md"
  expect FAIL 'mutation(.claude factory copy)' skill-copies "$m"; reset_wt "$m"
  grep -v '^## Maintain' "$m/$DOC" > "$m/t" && mv "$m/t" "$m/$DOC"
  expect FAIL 'mutation(-## Maintain)' stage-parity "$m"; reset_wt "$m"
  grep -v '^## Maintain' "$m/$SK" > "$m/t" && mv "$m/t" "$m/$SK"
  expect FAIL 'mutation(-## Maintain SKILL)' stage-parity "$m"; reset_wt "$m"
  grep -v '^Maintain ' "$m/README.md" > "$m/t" && mv "$m/t" "$m/README.md"
  expect FAIL 'mutation(-Maintain README)' stage-parity "$m"; reset_wt "$m"
  sed -i.bak 's/^## Maintain/## Test/' "$m/$DOC"
  expect FAIL 'mutation(## Maintain→## Test)' stage-parity "$m"; reset_wt "$m"
  sed -i.bak 's/^## Maintain/## Test/' "$m/$SK"
  expect FAIL 'mutation(## Maintain→## Test SKILL)' stage-parity "$m"; reset_wt "$m"
  sed -i.bak 's/^Maintain ─►/Test ──►/' "$m/README.md"
  expect FAIL 'mutation(Maintain─►→Test README)' stage-parity "$m"; reset_wt "$m"
  # agents-commands: rewrite the ## Commands block with every --list name (control: ok), then all but one (FAIL)
  commands_block() { awk '/^## Commands/{c=1;next} /^## /{c=0} !c' "$m/AGENTS.md"; echo; echo '## Commands'; echo; list_checks | sed "$1" | sed 's/.*/`&`/' | tr '\n' ' '; echo; }
  commands_block '' > "$m/AGENTS.tmp" && mv "$m/AGENTS.tmp" "$m/AGENTS.md"
  expect ok 'mutation(full block)' agents-commands "$m"; reset_wt "$m"
  commands_block 1d > "$m/AGENTS.tmp" && mv "$m/AGENTS.tmp" "$m/AGENTS.md"
  expect FAIL 'mutation(one name deleted)' agents-commands "$m"; reset_wt "$m"

  # sha witnesses — regression (single file via git show)
  for s in 7e8a195 da9eb33; do sha_row FAIL "$s" t1-trust-wording $FO; done
  sha_row ok   4e9b547 t1-trust-wording $FO
  sha_row FAIL da9eb33 t1-log-clobber $FO
  sha_row ok   4e9b547 t1-log-clobber $FO
  for s in 7e8a195 da9eb33; do sha_row FAIL "$s" t1-spawn-session $FO; done
  sha_row ok   4e9b547 t1-spawn-session $FO
  sha_row FAIL 43b63dc t3-label-drift AGENTS.md
  sha_row ok   92e6a25 t3-label-drift AGENTS.md
  sha_row FAIL 43b63dc t3-precedence AGENTS.md
  sha_row ok   92e6a25 t3-precedence AGENTS.md

  # per-clause mutations on the good-sha copy
  showfile 4e9b547 $FO; echo REFUSES >>"$T";                                          expect FAIL 'mutation(+REFUSES)' t1-trust-wording "$T"
  showfile 4e9b547 $FO; sed -i.bak 's/trust dialog is SKIPPED/trust dialog is shown/' "$T"; expect FAIL 'mutation(SKIPPED→shown)' t1-trust-wording "$T"
  showfile 92e6a25 AGENTS.md; echo 'never auto-apply labels' >>"$T";                  expect FAIL 'mutation(+never auto-apply labels)' t3-label-drift "$T"
  showfile 92e6a25 AGENTS.md; sed -i.bak 's/does NOT apply/does not apply/' "$T";     expect FAIL 'mutation(NOT→not)' t3-label-drift "$T"

  # lane classifier (ADR 0003) — historic ranges with known shapes; a wrong lane is a wrong review budget
  lane_expect() {  # lane_expect <T0|T1|T2> <sha>
    wn=$((wn+1)); lane_of . "$2~1..$2"
    if [ "$lane" = "$1" ]; then echo "witness ok: lane @$2 expected $1 ($lane_why)"
    else echo "witness FAIL: lane @$2 expected $1, got $lane — $lane_why"; wfail=1; fi
  }
  for s in 87123aa f66d79b 1c8067a a7f7523; do have_sha "$s" || exit 2; done
  lane_expect T0 87123aa   # one docs/training file, 16 lines
  lane_expect T1 f66d79b   # STATUS.md only — the board floors at T1
  lane_expect T2 1c8067a   # the synced trio (protected), 6 files
  lane_expect T2 a7f7523   # .githooks + bootstrap.sh + hooks.json (protected)
  local l=$m; reset_wt "$l"   # reuse the HEAD worktree opened for the mutation rows above
  printf 'x\n' >> "$l/docs/training/onboarding-runbook.md"; lane_of "$l" HEAD; wn=$((wn+1))
  [ "$lane" = T0 ] && echo "witness ok: lane @mutation(one .md, dirty tree) expected T0 ($lane_why)" || { echo "witness FAIL: lane @mutation(one .md) expected T0, got $lane — $lane_why"; wfail=1; }; reset_wt "$l"
  printf 'x\n' >> "$l/tests/validate.sh"; lane_of "$l" HEAD; wn=$((wn+1))
  [ "$lane" = T2 ] && echo "witness ok: lane @mutation(tests/validate.sh) expected T2 ($lane_why)" || { echo "witness FAIL: lane @mutation(tests/validate.sh) expected T2, got $lane — $lane_why"; wfail=1; }; reset_wt "$l"

  echo "$wn witnesses, $wfail unexpected"
  exit $wfail
}

case ${1:-} in
  --list) list_checks; exit 0 ;;
  --witness) witness_run ;;
  --lane) lane_run "${2:-}"; exit 0 ;;
  --*) echo "usage: $0 [<range>|--list|--witness|--lane [<range>]]" >&2; exit 2 ;;
esac

default_run "${1:-}"
exit $fail
