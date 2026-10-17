#!/usr/bin/env bash
# scrub-ai-attribution.sh - remove AI co-author trailers and AI-authored
# identities from a repo's git history, keeping every commit, tree and date.
#
# Usage: scrub-ai-attribution.sh audit   OWNER/REPO   clone a bare mirror, report, change nothing
#        scrub-ai-attribution.sh rewrite OWNER/REPO   rewrite the mirror locally, verify, report
#        scrub-ai-attribution.sh push    OWNER/REPO   publish the rewritten mirror (asks first)
#
# Removed from every commit message:
#   Co-Authored-By: Claude ... <noreply@anthropic.com>   (any case, any model name)
#   Generated with [Claude Code](...)                    (any form)
#   Claude-Session: https://claude.ai/code/...
# Changed on commits authored or committed as Claude <noreply@anthropic.com>:
#   author/committer become $AUTHOR_NAME <$AUTHOR_EMAIL> (defaults: git config --global)
# Never changed: dates, trees, the number of commits, other authors.
#
# Env: SCRUB_DIR (default ~/.cache/github-bullseye/scrub), AUTHOR_NAME, AUTHOR_EMAIL,
#      FIX_LOCAL_EMAIL=1 also moves commits authored as *@*.local to AUTHOR_EMAIL
#      (off by default: those are usually old and would flood the commits slice),
#      YES=1 skips the confirmation on push.
set -euo pipefail

cmd="${1:-}"; repo="${2:-}"
[ -n "$cmd" ] && [ -n "$repo" ] || { sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
case "$repo" in */*) ;; *) echo "repo must be OWNER/REPO" >&2; exit 2 ;; esac

SCRUB_DIR="${SCRUB_DIR:-$HOME/.cache/github-bullseye/scrub}"
AUTHOR_NAME="${AUTHOR_NAME:-$(git config --global user.name)}"
AUTHOR_EMAIL="${AUTHOR_EMAIL:-$(git config --global user.email)}"
export AUTHOR_NAME AUTHOR_EMAIL FIX_LOCAL_EMAIL="${FIX_LOCAL_EMAIL:-0}"
mirror="$SCRUB_DIR/${repo//\//__}.git"

AI_RE='co-authored-by:.*(claude|anthropic\.com)|generated with \[?claude code|^claude-session:'

report() { # report <label>
  local total trailers ai_auth local_auth
  total=$(git rev-list --branches --tags --count)
  trailers=$(git log --branches --tags --format='%B' | grep -ciE "$AI_RE" || true)
  ai_auth=$(git log --branches --tags --format='%ae%n%ce' | grep -c 'noreply@anthropic.com' || true)
  local_auth=$(git log --branches --tags --format='%ae' | grep -c '\.local$' || true)
  printf '  %-7s commits=%-5s ai-trailer-lines=%-5s ai-author-or-committer=%-5s local-email-authors=%s\n' \
    "$1" "$total" "$trailers" "$ai_auth" "$local_auth"
}

fingerprint() { git log --branches --tags --format='%at %ct %T %s' | sort; }

msg_filter='python3 -I -c "
import sys, re
ai = re.compile(r\"^\s*(co-authored-by:.*(claude|anthropic\.com)|.*generated with \[?claude code|claude-session:)\", re.I)
lines = [l for l in sys.stdin.read().split(chr(10)) if not ai.match(l)]
sys.stdout.write(chr(10).join(lines).rstrip(chr(10)) + chr(10))
"'

env_filter='
  fix() { case "$1" in noreply@anthropic.com) return 0 ;; *.local) [ "$FIX_LOCAL_EMAIL" = 1 ] ;; *) return 1 ;; esac; }
  if fix "$GIT_AUTHOR_EMAIL"; then GIT_AUTHOR_NAME="$AUTHOR_NAME"; GIT_AUTHOR_EMAIL="$AUTHOR_EMAIL"; fi
  if fix "$GIT_COMMITTER_EMAIL"; then GIT_COMMITTER_NAME="$AUTHOR_NAME"; GIT_COMMITTER_EMAIL="$AUTHOR_EMAIL"; fi
  export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL'

case "$cmd" in
  audit)
    rm -rf "$mirror" "$mirror.before" "$mirror.after"; mkdir -p "$SCRUB_DIR"
    git clone -q --bare "git@github.com:${repo}.git" "$mirror"
    cd "$mirror"; git ls-remote --heads --tags origin > "$mirror.remote-at-audit"
    echo "$repo"; report before
    ;;
  rewrite)
    [ -d "$mirror" ] || { echo "run audit first (no mirror at $mirror)" >&2; exit 1; }
    cd "$mirror"; echo "$repo"; report before
    fingerprint > "$mirror.before"
    export FILTER_BRANCH_SQUELCH_WARNING=1
    # Full refnames, not --branches --tags: a branch and a tag with the same
    # name make the short name ambiguous and filter-branch then skips both.
    # shellcheck disable=SC2046
    git filter-branch -f --tag-name-filter cat --msg-filter "$msg_filter" --env-filter "$env_filter" \
      -- $(git for-each-ref --format='%(refname)' refs/heads refs/tags) >/dev/null
    git for-each-ref --format='%(refname)' refs/original/ | while read -r ref; do git update-ref -d "$ref"; done
    git reflog expire --expire=now --all && git gc -q --prune=now
    fingerprint > "$mirror.after"
    report after
    if cmp -s "$mirror.before" "$mirror.after"; then
      echo "  dates, trees and subjects unchanged on every commit: OK"
    else
      echo "  WARNING: fingerprint changed; inspect before pushing:"; diff "$mirror.before" "$mirror.after" | head -20; exit 1
    fi
    ;;
  push)
    [ -d "$mirror" ] && [ -f "$mirror.after" ] || { echo "run rewrite first" >&2; exit 1; }
    cd "$mirror"; echo "$repo"; report mirror
    # Refuse if anything was pushed to GitHub since the audit: the mirror
    # would overwrite it. Re-run audit and rewrite instead.
    if ! git ls-remote --heads --tags origin | cmp -s - "$mirror.remote-at-audit"; then
      echo "  STOP: $repo changed on GitHub since the audit (a session pushed). Refs that differ:"
      diff <(sort "$mirror.remote-at-audit") <(git ls-remote --heads --tags origin | sort) | grep '^[<>]' | head
      echo "  Stop that session, then run audit and rewrite again."; exit 1
    fi
    # Fetch GitHub's current heads into refs/remotes/origin/* (never into
    # refs/heads/*, which hold the rewrite) so the push can send a thin pack
    # of just the new commits. Without this, after gc the mirror lacks the
    # old commits, cannot see what GitHub already has, and sends every blob;
    # a 2 GiB repo then hits GitHub's pack limit.
    git fetch -q origin '+refs/heads/*:refs/remotes/origin/*'
    echo "  This replaces every branch and tag of $repo on GitHub with the rewritten history."
    echo "  Every other clone must then run:  git fetch origin && git reset --hard origin/<branch>"
    if [ "${YES:-0}" != 1 ]; then
      read -r -p "  Type the repo name to continue: " ans
      [ "$ans" = "${repo#*/}" ] || { echo "aborted"; exit 1; }
    fi
    # Lease every ref on the value it had at audit time: GitHub rejects the
    # push atomically if a session moved any of them since, even in the
    # moment between the check above and the push.
    leases=()
    while read -r sha ref; do leases+=("--force-with-lease=${ref}:${sha}"); done < "$mirror.remote-at-audit"
    if git push -q --atomic "${leases[@]}" origin 'refs/heads/*:refs/heads/*' 'refs/tags/*:refs/tags/*'; then
      echo "  pushed. GitHub recomputes the Contributors graph in the background; allow a few minutes."
    else
      echo "  PUSH REJECTED: nothing on GitHub was changed. Run audit and rewrite again, then push."; exit 1
    fi
    ;;
  *) echo "unknown command: $cmd" >&2; exit 2 ;;
esac
