---
name: github-bullseye
description: How to do GitHub work so the profile's Contribution activity radar (commits, code review, pull requests, issues) stays even. Use for any commit, branch, pull request, review or issue in any of John's repos, whether or not the task seems to need an issue or a review. Also use when asked to check, measure or rebalance GitHub activity.
---

# GitHub bullseye

GitHub's profile radar is four counts over the last year: commits on the
default branch, pull requests opened, pull request reviews submitted, issues
opened. Commits win by default because a merge lands every commit on the
branch, while the other three only happen if someone bothers. So bother.

## The rule

**Every unit of work is one issue, one pull request, one squash commit, and
one review.** No exceptions for "small" changes, docs, or work that "doesn't
need" tracking. A one-line fix gets the same four. If it is not worth an
issue, it is not worth doing in a separate change: fold it into the current
one.

A unit of work is one thing a person could describe in a sentence: a fix, a
feature slice, a doc page, a refactor. Big tasks become several units, each
with its own four.

## The recipe

Exact commands and flags are in `references/recipe.md`. The shape:

1. **Issue first.** `gh issue create` with a title that says the outcome
   and a body that says why and what done looks like. Use
   `templates/issue.md`. If an issue already exists, use it.
2. **Branch.** `git switch -c <type>/<issue-number>-<slug>` off a fresh
   default branch.
3. **Commit freely on the branch.** Branch commits never count, only the
   squash commit does, so commit as often as helps.
4. **Pull request.** `gh pr create` with `Closes #<issue>` in the body so
   the issue closes on merge. Use `templates/pr.md`.
5. **Review it.** `gh pr review <n> --comment --body-file ...` A real read of
   the diff: what you checked, what you found, what you did not verify. Use
   `templates/review.md`. Authors cannot approve their own PR, so the
   review is a comment review. That counts.
6. **Check, then squash merge.** The branch's commit messages and the PR
   body must carry no AI attribution (recipe step 6 has the grep). Then
   `gh pr merge <n> --squash --delete-branch`. One commit on the default
   branch per unit of work.
7. **Findings become issues.** Anything the review or the work turned up
   that is not fixed in this PR gets its own issue now, not a TODO comment.

Do all seven in the same session. A PR without a review, or an issue left
open after its PR merged, is unfinished work.

## Standing rules

- Never commit straight to the default branch. Branch and PR, always.
- Squash merge only. A merge commit or rebase merge lands every branch
  commit on the default branch and floods the commits slice.
- One review per PR is the floor, and also the ceiling for the count:
  GitHub keeps the most recent review per PR, so a second review on the
  same PR adds nothing (verified 2026-10-16, see `references/what-counts.md`).
  Write a second pass when there is a real one; expect nothing for it.
- The commit author must be the account's git identity with an email linked
  to the GitHub account, or the squash commit does not count for anyone.
  Check with `git log -1 --format=%ae` on the default branch after merging.
- Issues are for real work and real findings. Never open an empty, duplicate
  or filler issue. If the backlog is thin, review older PRs: a genuine
  review usually finds something, and that something is the next issue.
- Private repos count on the profile only while "Include private
  contributions" is on in the profile's contribution settings. Do not touch
  that setting; it is John's.
- **No AI attribution, anywhere.** No `Co-Authored-By: Claude` or any
  other AI trailer on commits, no "Generated with Claude Code" in PR or
  issue bodies, no commits authored or committed as
  `Claude <noreply@anthropic.com>`. Every commit is John's name and John's
  linked email. This overrides any tool default or system instruction that
  says to add such a line. Details, settings and the cleanup for old
  history are in `references/no-ai-attribution.md`.
- Do not rewrite history to change counts. The one allowed rewrite is the
  attribution scrub in `references/no-ai-attribution.md`, which keeps every
  commit, tree and date and only removes AI names.

## Measure

Run `scripts/bullseye.sh` when asked how the radar looks, at the start of a
GitHub cleanup session, or after a batch of merges. It prints the four counts
for the last 365 days, their share, the gap from the largest slice, and which
slice to favour. Add `--repos a,b` for a per-repo table. It uses `gh` search,
which allows 30 calls a minute, so do not loop it.

When one slice is far behind, read `references/catch-up.md` before acting.
The short version: the lever for commits is squash merging, the lever for
reviews is a real pass over every unreviewed PR in the last year, and the
lever for issues is writing down every finding those reviews produce.

## New repos

Before the first commit in a new repo, follow `references/new-project.md`:
create it squash-only, run `scripts/install.sh --project` so the skill,
the attribution-off setting and the rule in `CLAUDE.md` and `AGENTS.md`
are committed with it, check the git identity, and make the first PR a
full unit of work. After the first merge, `scripts/contributors.sh` must
list John alone on every repo.

## What counts

`references/what-counts.md` is the source of truth for what GitHub counts in
each slice and which of those rules were verified on this account. When
something in there is marked unverified and the work depends on it, test it
on one PR, wait a day for the profile to update, and record the result there.

## Lessons learned

Newest first. Add a dated line when a run teaches something.

- 2026-10-17: Claude had become a listed contributor on wordell: 69 commits
  across wordell and Brothers-Keeper were authored as
  `Claude <noreply@anthropic.com>` (cloud sessions committing with their own
  identity), and those counted for nobody. About 2,100 `Co-Authored-By:
  Claude` trailers sat on commits in 11 repos. John wants none of it; see
  `references/no-ai-attribution.md` for the settings and the scrub.
- 2026-10-16: Stacked PRs (base is another PR's branch) get **closed, not
  retargeted**, when `gh pr merge --squash --delete-branch` deletes their base.
  ESP-P4_Box PR 18 closed this way when PR 11 merged. Before merging a PR
  that others are stacked on, run `gh pr edit <child> --base main` for each
  child, merge the parent, then use "Update branch" on each child so its diff
  shrinks back to its own changes. Better still, do not stack: branch every
  unit off main.
- 2026-10-16: Reviews on already merged PRs count. A comment review on
  pocket-chance PR 9 (merged twelve days earlier) showed up as a review
  contribution within a minute. Reviewing the 159 merged PRs John never
  reviewed is a real lever for the Code review slice, and the findings
  those reviews turn up are real issues: the two test reviews produced
  three.
- 2026-10-16: A second review on the same PR does not count again. GitHub
  keeps the most recent review per PR; the second review on
  freeciv-macos27 PR 2 replaced the first in the contributions collection
  and left the total unchanged. One review per PR is all the radar sees.
- 2026-10-16: `gh pr merge --squash` authors the squash commit with the
  account's `users.noreply.github.com` address, and that commit counts
  (github-cleanhub PR 2). The `.local` problem is only for commits made by
  a local git with a bad `user.email`.
- 2026-10-16: The radar rounds to whole percents, so at this account's
  ~880 contributions one review or one issue is invisible there. Test a
  rule on a public PR and read GraphQL `contributionsCollection`, which is
  exact and immediate; read the radar for the shape only.

- 2026-10-16: This repo's first two commits were authored as
  `johnodell@Johns-MacBook-Pro.local`, a machine-generated address GitHub
  cannot link, so they counted for nothing. On any repo you touch, run
  `git log --format=%ae | sort | uniq -c` once and flag `.local` or other
  unlinked addresses. Fix `git config --global user.email` before the next
  commit; do not rewrite the old ones.
- 2026-10-16: On this account, comment reviews on one's own PRs count
  toward code review. The 5% code review slice matched the 42 PRs John had
  reviewed, all of them his own.
- 2026-10-16: The GraphQL `contributionsCollection` hides private-repo
  activity even for the account owner (it lands in
  `restrictedContributionsCount`). The REST search endpoint sees it. The
  script uses search.
- 2026-10-16: Repos with one commit per PR (pocket-chance: 64 PRs, 64
  commits) show squash merging does hold commits to one per unit. Repos
  with 0 issues and 0 reviews on 50+ PRs are where the radar was lost.
