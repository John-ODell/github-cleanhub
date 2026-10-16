#!/usr/bin/env bash
# install.sh - link the github-bullseye skill where Claude Code and Codex look.
#
# Usage: install.sh                 link into ~/.claude/skills and ~/.agents/skills
#        install.sh --project DIR   also link into DIR/.claude/skills and
#                                   DIR/.agents/skills, and add a pointer to
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

if [ "$uninstall" -eq 1 ]; then
  unlink_ "$HOME/.claude/skills"
  unlink_ "$HOME/.agents/skills"
  exit 0
fi

link "$HOME/.claude/skills"     # Claude Code, user level
link "$HOME/.agents/skills"     # Codex, user level

if [ -n "$project" ]; then
  [ -d "$project" ] || { echo "no such directory: $project" >&2; exit 1; }
  link "$project/.claude/skills"
  link "$project/.agents/skills"
  pointer="## GitHub work

Follow the \`$name\` skill (linked under \`.claude/skills/\` and \`.agents/skills/\`)
for every commit, branch, pull request, review and issue: one issue, one PR,
one squash commit, one review per unit of work. Source:
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
