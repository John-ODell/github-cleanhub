#!/usr/bin/env bash
# bullseye.sh - measure the four slices of GitHub's Contribution activity radar.
#
# Usage: bullseye.sh [--user LOGIN] [--since YYYY-MM-DD] [--repos a,b,c] [--json]
#
# Counts, for the last 365 days (or since --since): issues opened, pull
# requests opened, pull requests reviewed, and commits authored, using the
# REST search API through `gh`. GraphQL hides private-repo activity even for
# the owner, so search is the source that matches the profile radar.
#
# Search allows 30 requests a minute. The global view uses 4; each --repos
# entry uses 4 more. The script sleeps between calls to stay under it.
set -euo pipefail

user=""
since=""
repos=""
json=0

while [ $# -gt 0 ]; do
  case "$1" in
    --user)  user="$2"; shift 2 ;;
    --since) since="$2"; shift 2 ;;
    --repos) repos="$2"; shift 2 ;;
    --json)  json=1; shift ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

command -v gh >/dev/null || { echo "gh is not installed" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "gh is not signed in (run: gh auth login)" >&2; exit 1; }

[ -n "$user" ] || user="$(gh api user --jq .login)"
if [ -z "$since" ]; then
  if date -v-365d +%F >/dev/null 2>&1; then since="$(date -v-365d +%F)"   # macOS
  else since="$(date -d '365 days ago' +%F)"; fi                             # GNU
fi

count() { # count <search-endpoint> <query>
  local n
  n="$(gh api "search/$1?q=$2&per_page=1" --jq .total_count 2>/dev/null)" || n="?"
  sleep 2
  echo "$n"
}

four() { # four <repo-qualifier or empty> -> "issues prs reviews commits"
  local q="$1"
  local i p r c
  i="$(count issues  "${q}author:${user}+is:issue+created:>=${since}")"
  p="$(count issues  "${q}author:${user}+is:pr+created:>=${since}")"
  r="$(count issues  "${q}reviewed-by:${user}+is:pr+updated:>=${since}")"
  c="$(count commits "${q}author:${user}+author-date:>=${since}")"
  echo "$i $p $r $c"
}

read -r issues prs reviews commits <<<"$(four "")"
for v in issues prs reviews commits; do
  [ "${!v}" != "?" ] || { echo "search failed for $v (rate limit? run: gh api rate_limit --jq .resources.search)" >&2; exit 1; }
done

total=$((issues + prs + reviews + commits))
max=$commits; for v in issues prs reviews; do [ "${!v}" -gt "$max" ] && max="${!v}"; done
pct() { [ "$total" -gt 0 ] && echo $(( (100 * $1 + total / 2) / total )) || echo 0; }
min=$commits; for v in issues prs reviews; do [ "${!v}" -lt "$min" ] && min="${!v}"; done
balance=0; [ "$max" -gt 0 ] && balance=$(( 100 * min / max ))

if [ "$json" -eq 1 ]; then
  printf '{"user":"%s","since":"%s","issues":%d,"pull_requests":%d,"code_review":%d,"commits":%d,"total":%d,"balance":%d}\n' \
    "$user" "$since" "$issues" "$prs" "$reviews" "$commits" "$total" "$balance"
else
  echo "Contribution radar for $user since $since (search API, includes private repos the token can see)"
  echo
  printf '  %-14s %6s %5s %10s\n' slice count share "gap to max"
  printf '  %-14s %6d %4d%% %10d\n' commits       "$commits" "$(pct "$commits")" $((max - commits))
  printf '  %-14s %6d %4d%% %10d\n' "code review" "$reviews" "$(pct "$reviews")" $((max - reviews))
  printf '  %-14s %6d %4d%% %10d\n' "pull requests" "$prs"   "$(pct "$prs")"     $((max - prs))
  printf '  %-14s %6d %4d%% %10d\n' issues        "$issues"  "$(pct "$issues")"  $((max - issues))
  echo
  echo "  total $total   bullseye = 25% each   balance (min/max) = ${balance}%"
  echo
  if [ "$balance" -ge 80 ]; then
    echo "  Shape: close to a bullseye. Keep every unit at 1 issue, 1 PR, 1 squash commit, 1 review."
  else
    echo "  Favour next, biggest gap first:"
    printf '%s\n' "$((max - reviews)) code review" "$((max - issues)) issues" "$((max - prs)) pull requests" "$((max - commits)) commits" \
      | sort -rn | awk '$1 > 0 { printf "    %-14s short by %d\n", substr($0, index($0,$2)), $1 }'
    [ "$commits" -eq "$max" ] && echo "    commits lead: squash-merge only, never commit to the default branch directly."
    echo "  See references/catch-up.md for the levers."
  fi
fi

if [ -n "$repos" ]; then
  owner="$user"
  echo
  printf '  %-28s %7s %5s %8s %8s\n' repo issues prs reviews commits
  IFS=',' read -r -a list <<<"$repos"
  for r in "${list[@]}"; do
    r="${r// /}"; [ -n "$r" ] || continue
    case "$r" in */*) full="$r" ;; *) full="$owner/$r" ;; esac
    read -r i p rv c <<<"$(four "repo:${full}+")"
    printf '  %-28s %7s %5s %8s %8s\n' "$full" "$i" "$p" "$rv" "$c"
  done
fi
