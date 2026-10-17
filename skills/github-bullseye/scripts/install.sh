#!/usr/bin/env bash
# install.sh - link the github-bullseye skill where Claude Code and Codex look.
#
# Usage: install.sh                 link into ~/.claude/skills and ~/.agents/skills,
#                                   and turn AI attribution off in ~/.claude/settings.json
#        install.sh --project DIR   also link into DIR/.claude/skills and
#                                   DIR/.agents/skills, turn attribution off in
#                                   DIR/.claude/settings.json, and add a pointer to
#                                   DIR/CLAUDE.md and DIR/AGENTS.md
#        install.sh --uninstall     remove the user-level links
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"   # the skill folder
name="$(basename "$here")"
project=""
uninstall=0

while [ $# -gt 0 ]; do
  case "$1" in
    --project) project="$2"; shift 2 ;;
    --uninstall) uninstall=1; shift ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

link() { # link <skills-dir>
  mkdir -p "$1"
  if [ -L "$1/$name" ] || [ ! -e "$1/$name" ]; then
    ln -sfn "$here" "$1/$name"
    echo "linked  $1/$name -> $here"
  else
    echo "skipped $1/$name (exists and is not a symlink)" >&2
  fi
}

unlink_() { [ -L "$1/$name" ] && rm "$1/$name" && echo "removed $1/$name" || true; }

no_attribution() { # no_attribution <settings.json>: merge the keys that stop Claude Code adding AI trailers
  mkdir -p "$(dirname "$1")"
  python3 -I - "$1" <<'PY'
import json, sys, os
p = sys.argv[1]
s = {}
if os.path.exists(p):
    with open(p) as f:
        s = json.load(f)
s["attribution"] = {"commit": "", "pr": ""}
s["includeCoAuthoredBy"] = False
with open(p, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
print("set attribution off in " + p)
PY
}

if [ "$uninstall" -eq 1 ]; then
  unlink_ "$HOME/.claude/skills"
  unlink_ "$HOME/.agents/skills"
  exit 0
fi

link "$HOME/.claude/skills"     # Claude Code, user level
link "$HOME/.agents/skills"     # Codex, user level
no_attribution "$HOME/.claude/settings.json"

if [ -n "$project" ]; then
  [ -d "$project" ] || { echo "no such directory: $project" >&2; exit 1; }
  link "$project/.claude/skills"
  link "$project/.agents/skills"
  no_attribution "$project/.claude/settings.json"
  pointer="## GitHub work

Follow the \`$name\` skill (linked under \`.claude/skills/\` and \`.agents/skills/\`)
for every commit, branch, pull request, review and issue: one issue, one PR,
one squash commit, one review per unit of work. No AI attribution anywhere:
no Co-Authored-By trailers, no \"Generated with\" footers, every commit in
John's name and linked email. Source:
https://github.com/John-ODell/github-cleanhub"
  for f in CLAUDE.md AGENTS.md; do
    if [ -f "$project/$f" ] && grep -q "$name" "$project/$f"; then
      echo "pointer already in $project/$f"
    else
      printf '\n%s\n' "$pointer" >> "$project/$f"
      echo "added pointer to $project/$f"
    fi
  done
fi
