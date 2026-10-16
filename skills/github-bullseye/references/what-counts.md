# What GitHub counts in each slice

The profile's **Contribution activity** radar splits the last year's
contributions into Commits, Code review, Pull requests and Issues and shows
each as a percentage of the total. Each line below says whether it comes from
GitHub's docs, was verified on John's account, or is still a guess. Keep that
honesty when editing.

Sources: GitHub Docs, "What counts as a contribution"
(docs.github.com/en/account-and-profile/reference/profile-contributions-reference)
and "Why are my contributions not showing up on my profile". Verified lines
were checked on 2026-10-16 against the REST search API and the radar on
John's profile (61% commits, 25% PRs, 9% issues, 5% review). The two Code
review tests the same day also used GraphQL `contributionsCollection` and
the profile's activity feed; the method is under "Measuring" below.

## Commits

- Count only on the **default branch** or `gh-pages`. Branch commits do not
  count until they land there. (Docs.)
- The commit's **author email must be linked** to the GitHub account, or be
  the account's `noreply` address. (Docs.)
- The repo must be **standalone, not a fork**. (Docs.)
- Each commit counts once. A **squash merge** therefore adds exactly one;
  a merge commit or rebase merge adds every commit on the branch. (Docs for
  the first part; verified for squash: pocket-chance has 64 PRs and 64
  commits in the window.)
- A squash merge made with `gh pr merge --squash` is authored as the
  account's `ID+LOGIN@users.noreply.github.com` address, and it counts.
  (Verified 2026-10-16: github-cleanhub `c782fea` is authored
  `149541420+John-ODell@users.noreply.github.com`, the API resolves its
  author to John-ODell, and `search/commits?q=repo:John-ODell/github-cleanhub+author:John-ODell`
  returns that one commit and neither of the two `.local` ones.)
- Can take **up to 24 hours** to appear on the profile. (Docs.)
- Counted by author date, so backdated commits land in the past. Do not do
  that; it is noise, and it is the kind of thing that gets a profile flagged.

## Issues

- Count when **opened** by the account in a **standalone repo, not a fork**.
  (Docs.)
- Counted at creation. Closing, commenting or editing does not add. (Docs
  imply; not separately verified.)
- Issues in private repos count on the profile only when "Include private
  contributions on my profile" is on. (Docs. On for John's account: the
  radar includes private repos.)

## Pull requests

- Count when **opened** by the account in a **standalone repo, not a fork**.
  (Docs.)
- Counted at creation, merged or not. (Docs imply; verified loosely: the 217
  PRs in the window include closed-unmerged ones and the radar's 25% matches
  that count.)
- A PR from a branch in the same repo and a PR from a fork both count for
  the author; the repo it targets must be standalone. (Docs.)

## Code review

- Counts when a **pull request review is submitted**. A review is the
  "Review changes" action, or `gh pr review`. A plain comment on the PR
  conversation is not a review. (Docs for the first part; the second is the
  product's definition of a review.)
- **Reviewing your own PR counts.** Authors cannot Approve or Request
  changes on their own PR, but a Comment review submits fine. (Verified
  2026-10-16: all 42 PRs John had reviewed were his own, and the radar's 5%
  matches 42 of 865.)
- **A review on an already merged PR counts.** (Verified 2026-10-16: a
  comment review on pocket-chance PR 9, merged 2026-10-04 and never
  reviewed, appeared within a minute as a node in GraphQL
  `contributionsCollection.pullRequestReviewContributions`, moved
  `totalPullRequestReviewContributions` from 1 to 2, and moved
  `bullseye.sh` code_review from 44 to 45; the profile's public "Reviewed
  N pull requests" line read 2 afterwards (only GraphQL was read before). The radar read 5% before and
  after: 45 of 884 still rounds to 5%, so the radar cannot show one
  review. Radar re-read after 24 hours: pending, see SKILL.md lessons.)
- **A second review on the same PR does not count again.** (Disproved
  2026-10-16: a second comment review on freeciv-macos27 PR 2, which
  already had one review that was the account's only public review node,
  left the total at 2 rather than 3. The old node was replaced by the new
  one and its `occurredAt` moved to the new review's time. GitHub's schema
  says so outright: `pullRequestReviewContributions` "Returns the most
  recently submitted review for each PR reviewed by the user".) So the
  Code review slice counts **PRs reviewed**, which is exactly what the
  `reviewed-by:` search counts. A second review re-dates a PR's one
  contribution; it never adds one. Do a second pass when there is a real
  one to write up, and expect nothing from it on the radar.

## Things that silently count for nothing

- Commits with an unlinked email (a Claude session with a stale
  `user.email`, a CI bot, a different machine, or git's default
  `user@hostname.local` on a fresh Mac). Check `git log -1 --format=%ae`
  after a merge. Seen on this account 2026-10-16: github-cleanhub's first
  two commits were `johnodell@Johns-MacBook-Pro.local` and never counted.
- Commits on any branch but the default one, including long-lived release
  branches.
- Anything in a fork, including PRs opened against your own fork.
- Discussions count as their own category and do not appear on the radar.
- Creating or forking a repo counts as a contribution on the calendar but
  not in any of the four radar slices.

## Measuring without the profile page

The GraphQL `contributionsCollection` is the obvious source and is wrong for
this account: private-repo activity lands in `restrictedContributionsCount`
with no breakdown, even with a `repo`-scoped token. The REST search
endpoint sees everything the token can see and reproduces the radar:

```
search/issues?q=author:LOGIN+is:issue+created:>=DATE      -> issues
search/issues?q=author:LOGIN+is:pr+created:>=DATE         -> pull requests
search/issues?q=reviewed-by:LOGIN+is:pr+updated:>=DATE    -> code review (PRs reviewed)
search/commits?q=author:LOGIN+author-date:>=DATE          -> commits
```

Search allows 30 requests a minute. The commits search returns commits on
every branch, so it slightly overcounts when there are unmerged branches;
on this account it matched the radar within rounding.

For a **public** repo, GraphQL is the exact instrument and updates within a
minute, which the radar's whole-percent rounding never will:

```
gh api graphql -f query='{ viewer { contributionsCollection {
  totalPullRequestReviewContributions
  pullRequestReviewContributions(first: 20, orderBy: {direction: DESC}) {
    nodes { occurredAt pullRequest { number repository { nameWithOwner } } } } } } }'
```

One node per PR reviewed (the most recent review), none for private repos.
Use it to test a rule on a public PR; use the search counts and the radar
for the whole picture. The profile's "Reviewed N pull requests in M
repositories" line (logged out, so public only) shows the same number.
