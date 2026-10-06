#!/usr/bin/env bash
# The new-project file step: copy files/** into <target-dir>, never overwriting.
#
#   scaffold.sh <target-dir> [--owner <o>] [--name <n>]
#
# Substitutes {{OWNER}} {{NAME}} {{PLUGIN_VERSION}} {{DATE}}; keeps each template's
# executable bit; prints `wrote: <path>` or `skip: <path>` per file. No GitHub, no commit.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
usage() { echo "usage: $0 <target-dir> [--owner <o>] [--name <n>]" >&2; exit 2; }
[ $# -ge 1 ] || usage
target=$1; shift; owner='<owner>'; name=""
while [ $# -gt 0 ]; do
  case $1 in
    --owner) [ $# -ge 2 ] || usage; owner=$2; shift 2 ;;
    --name)  [ $# -ge 2 ] || usage; name=$2; shift 2 ;;
    *) usage ;;
  esac
done
mkdir -p "$target"; target=$(cd "$target" && pwd)
name=${name:-${target##*/}}
# owner and name land in sed and in files: GitHub's own character set only
for v in "$owner" "$name"; do
  [ "$v" = '<owner>' ] || [[ $v =~ ^[A-Za-z0-9._-]+$ ]] || { echo "invalid owner/name: $v (use --owner/--name with A-Z a-z 0-9 . _ -)" >&2; exit 2; }
done
version=$(sed -nE 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$here/../../.claude-plugin/plugin.json")
[ -n "$version" ] || { echo "no version in plugin.json" >&2; exit 2; }
today=$(date +%Y-%m-%d)

cd "$here/files"
find . -type f | sed 's|^\./||' | sort | while IFS= read -r f; do
  if [ -e "$target/$f" ]; then echo "skip: $f"; continue; fi
  mkdir -p "$(dirname "$target/$f")"
  sed -e "s/{{OWNER}}/$owner/g" -e "s/{{NAME}}/$name/g" -e "s/{{PLUGIN_VERSION}}/$version/g" -e "s/{{DATE}}/$today/g" "$f" >"$target/$f"
  [ ! -x "$f" ] || chmod +x "$target/$f"
  echo "wrote: $f"
done
