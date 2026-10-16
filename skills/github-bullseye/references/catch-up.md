# Catch-up: pulling a lopsided radar back to even

The radar is a rolling 365-day window, so the past rolls off on its own.
Following the recipe from today makes every new unit 1:1:1:1, and the shape
drifts toward even over the year. Catch-up is for when that is too slow.

Run `scripts/bullseye.sh` first. It prints each slice's gap from the largest
one. Work the largest gaps, with these levers and only these.

## If commits are the big slice

- Make squash the only merge in every active repo (recipe step 0). This is
  the one lever that reduces future commits without reducing work.
- Stop committing to the default branch directly. Every direct commit is a
  commit with no issue, no PR and no review attached: the worst possible
  ratio.
- Do not delete or rewrite history to remove old commits.

## If code review is behind

- List the last year's PRs you have not reviewed, per repo:
  ```bash
  gh pr list --state all --limit 200 --search "author:LOGIN -reviewed-by:LOGIN created:>=DATE" --json number,title,mergedAt
  ```
- Review them for real, oldest first, with `gh pr diff` and a comment review
  from `templates/review.md`. A review of a merged PR reads the code as it
  shipped: does it still hold, did anything regress, is there a test
  missing. Those reviews produce findings, and the findings produce issues,
  which fixes two slices at once.
- Reviews on already-merged PRs count (verified 2026-10-16, see
  `what-counts.md`), so this lever is real. A second review on a PR you
  already reviewed counts nothing extra, so pick PRs with no review by you:
  the `-reviewed-by:LOGIN` filter above does that.

## If issues are behind

- Every finding from the catch-up reviews above becomes an issue. Real
  ones: a bug, a missing test, a doc gap, a follow-up the PR body promised.
- Walk each active repo's `TODO`, `FIXME` and `HACK` comments, and its
  README's "known issues" or "later" sections. Each is an issue that was
  never filed. File it, link the file and line, and leave the comment
  pointing at the issue number.
- Open the issue before the work, not after. An issue opened after its PR
  merged is the same count but reads as backfill.
- Do not open issues with no content, duplicates, or "track X" placeholders.
  If a repo really has nothing to file, it has nothing to file.

## If pull requests are behind

- Smaller units. One PR per sentence-sized change, each with its issue and
  review.
- Direct commits to the default branch are PRs that never happened. Stop
  them and the PR slice follows.

## What a week looks like during catch-up

With commits far ahead, a session that merges one unit of real work should
leave behind roughly: 1 squash commit, 1 PR, 2 or 3 reviews (its own plus
one or two older PRs), and 2 or 3 issues (its own plus the findings). The
script will say when to go back to 1:1:1:1.

## What not to do

- No empty issues, no "LGTM" reviews, no PRs that change whitespace. The
  shape should come from working differently, not from working at nothing.
- No bots or automation that open issues or reviews on a schedule.
- No backdated commits, no history rewrites, no second accounts.
