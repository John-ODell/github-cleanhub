# github-cleanhub

A reference for Claude and Codex on how to work on GitHub so the
**Contribution activity** radar on a profile is a bullseye: commits, code
review, pull requests and issues each near 25%.

```
            Code review
                |
   Commits -----+----- Issues
                |
          Pull requests
```

The radar is a share of four counts over the last year. Commits dominate on
most profiles because every commit on `main` counts once, while an issue, a
pull request and a review each count once per PR. The fix is a habit, not a
trick: **every unit of work is one issue, one pull request, one squash
commit, and one review.** That is the whole rule. The rest of this repo is
the detail an agent needs to do it right.

## Use it

Pick whichever fits the moment. The content is the same.

1. **Read it from the URL.** Tell Claude or Codex:
   `Read https://github.com/John-ODell/github-cleanhub and follow the github-bullseye skill for all GitHub work in this repo.`
2. **Install it as a skill** so it loads in every session on this machine:
   ```bash
   git clone git@github.com:John-ODell/github-cleanhub.git ~/github-cleanhub && ~/github-cleanhub/skills/github-bullseye/scripts/install.sh
   ```
   That links the skill into `~/.claude/skills/` (Claude Code) and
   `~/.agents/skills/` (Codex). Run it again with `--project /path/to/repo`
   to also link it into that project and add a pointer to its `CLAUDE.md`
   and `AGENTS.md`.
3. **Paste it.** Copy `skills/github-bullseye/SKILL.md` into the chat.

## What is here

| Path | What it is |
| --- | --- |
| [skills/github-bullseye/SKILL.md](skills/github-bullseye/SKILL.md) | The skill. Standing rules, the per-unit recipe, and when to run the script. |
| [references/what-counts.md](skills/github-bullseye/references/what-counts.md) | What GitHub actually counts in each slice, with what was verified on this account. |
| [references/recipe.md](skills/github-bullseye/references/recipe.md) | The exact `gh` commands for issue, branch, PR, review, squash merge. |
| [references/catch-up.md](skills/github-bullseye/references/catch-up.md) | How to pull a lopsided radar back to even without inventing work. |
| [scripts/bullseye.sh](skills/github-bullseye/scripts/bullseye.sh) | Measures the four counts for the last year and says what is behind. |
| [scripts/install.sh](skills/github-bullseye/scripts/install.sh) | Links the skill into Claude's and Codex's skill folders and turns AI attribution off. |
| [scripts/contributors.sh](skills/github-bullseye/scripts/contributors.sh) | Every repo's Contributors list; flags any login but John's and any AI attribution left in recent commits. |
| [references/new-project.md](skills/github-bullseye/references/new-project.md) | The ten-minute setup for a new repo so it starts clean. |
| [references/no-ai-attribution.md](skills/github-bullseye/references/no-ai-attribution.md) | No Claude trailers, footers or authorship anywhere; the settings and the scrub for old history. |
| [templates/](skills/github-bullseye/templates/) | Short issue, PR and review bodies. |

`CLAUDE.md` and `AGENTS.md` at the root make this repo itself load the skill
when opened in Claude Code or Codex, through the symlinks in
`.claude/skills/` and `.agents/skills/`.

## Measure

```bash
skills/github-bullseye/scripts/bullseye.sh
```

Prints the four counts for the last 365 days, their share, how far each slice
is from the largest one, and which to favour next. Needs `gh` signed in.
Add `--repos a,b,c` for a per-repo table.

## Scope

This repo is about the **shape** of activity, not its volume. Nothing here
asks an agent to open empty issues or rubber-stamp reviews. An issue is a
real task or finding. A review is a real read of the diff with at least one
substantive comment. The counts come out even because the habit is even.
