# Attribution scrub: status and what each session must do

Last updated 2026-10-17 by the github-cleanhub session. Paste the section
for your repo into the session working on it. Full background:
`skills/github-bullseye/references/no-ai-attribution.md`.

The scrub rewrites a repo's history so no commit is authored as Claude and
no commit message carries `Co-Authored-By: Claude`, `Claude-Session:` or
"Generated with Claude Code". Every commit, tree and date stays. Commit
hashes change, so **every clone of a rewritten repo must be reset once.**

## Rewritten and pushed: history is clean on GitHub

| Repo | Clones on this Mac that still need the reset below |
| --- | --- |
| Brothers-Keeper | `~/Desktop/final_finasty_game`, `~/Desktop/final_finasty_game_art` |
| Brothers-Keeper-Art | `~/Desktop/asset_generator` |
| website | `~/Desktop/website` and its four worktrees under `~/Desktop/website/.claude/worktrees/` |
| ESP-P4_Box | `~/Desktop/ESP-P4_Box`, and any clone the ESP32 P4 session uses |
| freeciv-macos27 | `~/Desktop/freeciv-port`, and any clone the Freeciv session uses |
| wordell | `~/Desktop/wordell` |
| ap-golf | `~/Desktop/AP_Golf_Game` and its worktrees (`AP_Golf_Art_Cleanup`, `AP_Golf_SwingFeel`, `.claude/worktrees/android-port-1add01`, `.claude/worktrees/app-icon`) |
| notesapp | `~/Desktop/Encrpyt_,my_notes` |
| pocket-chance | none on this Mac |
| qwen-play-harness | `~/Desktop/qwen-play-harness` |
| github-cleanhub | `~/Desktop/github-cleanhub` (`~/Desktop/github-cleanup` is an old clone; delete it) |

Verified before each push: the tip every clone had last fetched is in the
rewritten history, and the branch set on GitHub matched the mirror. Nothing
was dropped.

### Reset a clone of a rewritten repo

Run this in the clone, and in each of its worktrees, on whatever branch it
is on. Uncommitted work is stashed and restored; nothing is lost.

```bash
b=$(git branch --show-current) && git stash push -u -m pre-scrub-reset; git fetch origin && git reset --hard "origin/$b" && git stash pop
```

`git stash pop` saying "No stash entries found" means there was nothing to
stash. If the branch was never pushed, `origin/$b` does not exist: rebase it
onto the new main instead with
`git rebase --onto origin/main $(git merge-base origin/main HEAD)`.

Then confirm:

```bash
git log --format=%B | grep -ciE 'co-authored-by:.*claude|^claude-session:'   # must print 0
```

**Do not push from a clone that has not been reset.** A push from old
history re-introduces the old commits.

## History: all 11 repos done

Brothers-Keeper-Art was the last, pushed 2026-10-17 once its live session
paused (91 commits, 66 trailer lines removed). `scripts/contributors.sh
--all` now reports every repo John owns as clean: only `John-ODell` in each
Contributors list, no AI-authored commits, no attribution lines.

## PR and issue bodies: done

The "Generated with Claude Code" footer was removed from 230 PR and issue
bodies across every repo on 2026-10-17. Originals are backed up in
`~/.cache/github-bullseye/scrub/*.bodies.*.jsonl`.

## Going forward

Every session on this Mac has the setting off (`~/.claude/settings.json`:
`attribution` empty, `includeCoAuthoredBy` false) and the skill rule. For a
repo that other machines or cloud sessions touch, run once:

```bash
~/Desktop/github-cleanhub/skills/github-bullseye/scripts/install.sh --project /path/to/repo
```

It writes the setting into that repo's `.claude/settings.json` and adds
the rule to its `CLAUDE.md` and `AGENTS.md`.
