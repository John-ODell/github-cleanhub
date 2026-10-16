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
John's profile (61% commits, 25% PRs, 9% issues, 5% review).

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
- Whether a **second review on the same PR** counts again is unverified.
  website PR 39 has two comment reviews by John, and the radar could not
  tell 42 from 43. Assume one per PR when planning; do not stack reviews to
  find out.
- Whether a review on an **already merged or closed PR** counts is
  unverified. GitHub lets you submit one. Test on one old PR, wait a day,
  and record the answer here before relying on it for catch-up.

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
