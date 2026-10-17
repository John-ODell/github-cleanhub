# Starting a new repo

Ten minutes at the start keeps the radar even and the Contributors list
John's alone for the life of the repo. Do all of it before the first
commit.

## 1. Create it with squash as the only merge

```bash
gh repo create John-ODell/NAME --private --clone        # or --public
cd NAME
gh repo edit --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false --delete-branch-on-merge --enable-issues
```

## 2. Install the skill and turn attribution off in the repo

```bash
~/Desktop/github-cleanhub/skills/github-bullseye/scripts/install.sh --project "$PWD"
```

That links the skill under `.claude/skills/` and `.agents/skills/`, writes
`attribution: {commit: "", pr: ""}` and `includeCoAuthoredBy: false` into
`.claude/settings.json`, and appends the rule to `CLAUDE.md` and
`AGENTS.md`. Commit those files in the first PR so cloud sessions, Codex
and other machines get them from the clone, not from this Mac.

## 3. Check the identity every session will commit with

```bash
git config user.name && git config user.email
```

The email must be John's linked address or his `users.noreply.github.com`
address. A `.local` address or anything else means the commits count for
nobody. Fix with `git config --global user.email` before the first commit.

## 4. Make the first commit a unit of work

The first PR is the README plus the files step 2 created. It still gets an
issue, a comment review and a squash merge; that is the habit from commit
one. Use `references/recipe.md`.

## 5. After the first merge, check the record

```bash
git log -1 --format='%an <%ae>'                                      # John, linked email
gh api repos/John-ODell/NAME/contributors --jq '.[].login'           # John-ODell only
~/Desktop/github-cleanhub/skills/github-bullseye/scripts/contributors.sh   # every repo at once
```

## Cloud and other machines

A cloud session commits with whatever identity the Claude GitHub app is
given. Before 2026-10-17 that produced commits authored as
`Claude <noreply@anthropic.com>`, which put `claude` in the Contributors
list and counted for nobody. The repo's committed `.claude/settings.json`
and `CLAUDE.md` rule stop the trailer; the author identity on a cloud
session is John's to check on the first PR from it, with the step 5
commands. If a `claude` author shows up, the scrub in
`references/no-ai-attribution.md` fixes it.
