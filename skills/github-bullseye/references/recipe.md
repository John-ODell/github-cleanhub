# The recipe, with commands

Every unit of work, start to finish. `OWNER/REPO` is the repo you are in;
`gh` infers it from the checkout, so the `--repo` flag is only shown where
you might be elsewhere.

## 0. Once per repo: make squash the only merge

```bash
gh repo edit OWNER/REPO --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false --delete-branch-on-merge
```

This stops a stray merge-commit merge from landing twenty commits at once.
Do it the first time you touch a repo, and say so in the PR body.

## 1. Issue

```bash
gh issue create --title "Verb the outcome" --body-file issue.md
```

Fill `issue.md` from `templates/issue.md`. The title says the outcome, not
the activity ("Settings screen remembers the last tab", not "Work on
settings"). Capture the number it prints; call it `N`.

Look first: `gh issue list --search "keyword"`. If one exists, use it.

## 2. Branch

```bash
git switch main && git pull --ff-only
git switch -c fix/N-short-slug
```

Prefixes: `fix/`, `feat/`, `docs/`, `chore/`, `refactor/`. The issue number
in the branch name ties the branch to the issue for anyone reading `git
branch`.

## 3. Work and commit on the branch

Commit as often as helps. These commits do not reach the default branch
and never count, so they cost nothing. Each message still says what and
why, because they show in the PR.

## 4. Pull request

```bash
git push -u origin HEAD
gh pr create --title "Verb the outcome" --body-file pr.md
```

Fill `pr.md` from `templates/pr.md`. The body must contain `Closes #N` on
its own line so GitHub closes the issue on merge. Capture the PR number;
call it `P`.

## 5. Review

Read the diff as if someone else wrote it:

```bash
gh pr diff P
```

Then write the review from `templates/review.md` and submit it:

```bash
gh pr review P --comment --body-file review.md
```

`--comment` is the only kind an author can submit on their own PR, and it
counts. A review says what was checked, what was found, and what was not
verified. If it finds something worth fixing now, fix it on the branch,
push, and note it in the review. If it finds something for later, open an
issue (step 7) and link it from the review.

A review with nothing in it but "LGTM" is not a review. Say at least one
concrete thing you checked.

## 6. Squash merge

```bash
gh pr merge P --squash --delete-branch
```

Then confirm the squash commit is yours:

```bash
git switch main && git pull --ff-only && git log -1 --format='%an <%ae>  %s'
```

The email must be one linked to the GitHub account. If it is not, the
commit counted for nobody; fix `git config user.email` before the next unit.

## 7. Findings become issues

```bash
gh issue create --title "Verb the outcome" --body-file finding.md
```

One per finding. Link back: "Found while reviewing #P." These are the
issues that keep the issues slice honest, because they are real.

## In one screen

```bash
gh issue create --title "..." --body-file issue.md              # N
git switch -c fix/N-slug
# ... work, commit ...
git push -u origin HEAD
gh pr create --title "..." --body-file pr.md                    # P, body has "Closes #N"
gh pr diff P
gh pr review P --comment --body-file review.md
gh pr merge P --squash --delete-branch
git switch main && git pull --ff-only && git log -1 --format=%ae
# findings -> gh issue create ...
```
