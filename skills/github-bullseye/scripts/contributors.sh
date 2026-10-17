#!/usr/bin/env bash
# contributors.sh - who GitHub lists as a contributor on every repo the
# account owns, and whether any recent commit still carries AI attribution.
#
# Usage: contributors.sh [--user LOGIN] [--all]
#   Default: repos pushed in the last 18 months. --all: every repo.
# Flags any contributor login other than the owner, any commit in the last
# 100 on the default branch authored as noreply@anthropic.com, and any
# message there with a Co-Authored-By/Claude-Session/Generated-with line.
# Exit 1 when anything is flagged, so it can gate a cleanup session.
set -euo pipefail

user=""; all=0
while [ $# -gt 0 ]; do
  case "$1" in
    --user) user="$2"; shift 2 ;;
    --all) all=1; shift ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
command -v gh >/dev/null || { echo "gh is not installed" >&2; exit 1; }
[ -n "$user" ] || user="$(gh api user --jq .login)"

if [ "$all" -eq 1 ]; then since="1970-01-01"
elif date -v-18m +%F >/dev/null 2>&1; then since="$(date -v-18m +%F)"
else since="$(date -d '18 months ago' +%F)"; fi

AI='co-authored-by:.*(claude|anthropic)|claude-session:|generated with \[?claude code'
flagged=0
printf '%-32s %-30s %6s %6s\n' repo contributors ai-auth ai-msg
gh repo list "$user" --limit 200 --json name,pushedAt --jq ".[] | select(.pushedAt >= \"$since\") | .name" | sort |
while read -r r; do
  who=$(gh api "repos/$user/$r/contributors?per_page=100" --jq '[.[] | "\(.login)=\(.contributions)"] | join(",")' 2>/dev/null || echo "?")
  read -r ai msg <<<"$(gh api "repos/$user/$r/commits?per_page=100" 2>/dev/null | python3 -I -c '
import sys, json, re
try: cs = json.load(sys.stdin)
except Exception: print("? ?"); sys.exit()
ai = re.compile(sys.argv[1], re.I)
a = sum(1 for c in cs if "noreply@anthropic.com" in (c["commit"]["author"]["email"], c["commit"]["committer"]["email"]))
m = sum(1 for c in cs if ai.search(c["commit"]["message"]))
print(a, m)' "$AI")"
  mark=""
  case "$who" in *,*|"") mark="  <- other contributor" ;; esac
  [ "$ai" = "0" ] || mark="$mark  <- AI-authored commits"
  [ "$msg" = "0" ] || mark="$mark  <- attribution lines"
  printf '%-32s %-30s %6s %6s%s\n' "$r" "${who:0:30}" "$ai" "$msg" "$mark"
  [ -z "$mark" ] || echo "$r" >> "${TMPDIR:-/tmp}/contributors.flagged.$$"
done
if [ -f "${TMPDIR:-/tmp}/contributors.flagged.$$" ]; then
  echo; echo "flagged: $(tr '\n' ' ' < "${TMPDIR:-/tmp}/contributors.flagged.$$")"
  echo "see references/no-ai-attribution.md for the scrub"
  rm -f "${TMPDIR:-/tmp}/contributors.flagged.$$"; exit 1
fi
echo; echo "clean: every repo lists only $user, no AI-authored commits, no attribution lines in the last 100 commits"
