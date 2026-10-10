# github-cleanup

Private home-base repo for a recurring Claude cloud session that audits my GitHub projects and
does the work that is usually skipped: tracking real issues, opening small fix PRs, and
reviewing them.

- `CLAUDE.md` – instructions the session follows
- `REPOS.md` – which repos to sweep, and which to leave alone
- `.claude/agents/` – subagents (scout, issue writer, PR author, code reviewer)
- `.claude/skills/` – skills (audit, open issues, review PR, weekly sweep)
- `playbooks/` – guides for issues, PRs, reviews and scheduling
- `logs/activity-log.md` – record of every run

## Setup

1. Create a private repo named `github-cleanup` and push this folder to it.
2. Fill in the "Always include" and "Never touch" sections of `REPOS.md`.
3. Add a cloud environment (see `playbooks/scheduling.md`) and start a session in this repo with:
   "Run the weekly-sweep skill."
4. Once a run looks good, schedule it.
# github-cleanhub
