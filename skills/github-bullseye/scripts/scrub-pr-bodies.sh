#!/usr/bin/env bash
# scrub-pr-bodies.sh - remove "Generated with Claude Code" lines from the
# bodies of pull requests and issues in a repo. Backs up every original body
# first. Needs gh signed in with write access to the repo.
#
# Usage: scrub-pr-bodies.sh OWNER/REPO            edit matching PR and issue bodies
#        scrub-pr-bodies.sh OWNER/REPO --dry-run  list what would change
# Env: SCRUB_DIR (default ~/.cache/github-bullseye/scrub) for the backups
set -euo pipefail

repo="${1:-}"; dry="${2:-}"
[ -n "$repo" ] || { sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
SCRUB_DIR="${SCRUB_DIR:-$HOME/.cache/github-bullseye/scrub}"; mkdir -p "$SCRUB_DIR"
backup="$SCRUB_DIR/${repo//\//__}.bodies.$(date +%Y%m%d%H%M%S).jsonl"
list="$SCRUB_DIR/${repo//\//__}.bodies.list"

for kind in pr issue; do
  gh "$kind" list --repo "$repo" --state all --limit 1000 --search '"Generated with Claude Code"' \
    --json number,body --jq ".[] | select(.body | test(\"generated with \\\\[?claude code\"; \"i\")) | {kind: \"$kind\", number: .number, body: .body} | @json"
done > "$list"

n=$(wc -l < "$list" | tr -d ' ')
echo "$repo: $n bodies carry the line"
[ "$n" -gt 0 ] || exit 0
cp "$list" "$backup"

while read -r row; do
  kind=$(printf '%s' "$row" | python3 -I -c 'import sys,json; print(json.load(sys.stdin)["kind"])')
  num=$(printf '%s' "$row" | python3 -I -c 'import sys,json; print(json.load(sys.stdin)["number"])')
  if [ -n "$dry" ]; then echo "  would edit $kind #$num"; continue; fi
  printf '%s' "$row" | python3 -I -c '
import sys, json, re
body = json.load(sys.stdin)["body"]
ai = re.compile(r"^\s*.*generated with \[?claude code", re.I)
lines = [l for l in body.split("\n") if not ai.match(l)]
sys.stdout.write("\n".join(lines).rstrip("\n") + "\n")' > "$SCRUB_DIR/body.tmp"
  gh "$kind" edit "$num" --repo "$repo" --body-file "$SCRUB_DIR/body.tmp" >/dev/null && echo "  edited $kind #$num"
done < "$list"
rm -f "$SCRUB_DIR/body.tmp"
echo "originals backed up in $backup"
