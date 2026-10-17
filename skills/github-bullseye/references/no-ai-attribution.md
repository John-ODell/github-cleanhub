# No AI attribution

Commits, pull requests, issues and reviews in John's repos carry John's
name and nobody else's. No `Co-Authored-By: Claude`, no "Generated with
Claude Code", no commits authored as `Claude <noreply@anthropic.com>`. This
page is why, what to set so it stops, how to check, and how the old history
gets cleaned.

## Why it matters for the radar

- A commit **authored or committed** as `Claude <noreply@anthropic.com>`
  shows the `claude` GitHub account in the repo's Contributors list and
  counts for **nobody on John's profile**. Found 2026-10-17: 69 such
  commits in Brothers-Keeper and wordell; wordell's Contributors graph
  listed `claude` with 41 commits.
- A `Co-Authored-By: Claude ...` trailer does not reach the Contributors
  graph, but GitHub draws a second avatar on every such commit. Found
  2026-10-17: about 2,100 trailer lines across 11 repos.
- The "🤖 Generated with Claude Code" footer in PR and issue bodies is text
  only. It changes no count. It still goes, because the record should read
  as John's.
- A `Claude-Session: https://claude.ai/code/...` trailer, which cloud
  sessions add, is the same kind of thing. Found 2026-10-17: 267 of them in
  wordell, website, Brothers-Keeper and ap-golf. The scrub removes those
  too. Ordinary sentences that mention Claude Code as a tool ("hooks for
  Claude Code and Codex") are content, not attribution, and stay.

## Stop it going forward

Three layers, because any one of them can be skipped by a tool.

1. **Claude Code setting.** In `~/.claude/settings.json` (every project on
   this Mac) and in each repo's `.claude/settings.json` (cloud and other
   machines):
   ```json
   {
     "attribution": { "commit": "", "pr": "" },
     "includeCoAuthoredBy": false
   }
   ```
   `attribution` is the current key; empty strings mean no trailer and no
   PR footer. `includeCoAuthoredBy` is the older boolean and is kept for
   older versions. `scripts/install.sh` writes both; `--project DIR` writes
   them into that repo too.
2. **Standing instruction.** The pointer `install.sh --project` appends to
   `CLAUDE.md` and `AGENTS.md` says it in words, so Claude, Codex and any
   cloud session follow it even where the setting is absent. The skill's
   standing rules say it too.
3. **Check before merging.** Recipe step 6 greps the branch's commit
   messages and the PR body for attribution before the squash merge. The
   review template has a line for it.

Codex adds no trailer by itself; the `AGENTS.md` rule covers it anyway.
`git config user.email` must be John's linked address on every machine and
session that commits.

## Check a repo

```bash
git log --format='%ae%n%ce' | grep -c 'noreply@anthropic.com'        # AI-authored commits, want 0
git log --format=%B | grep -ciE 'co-authored-by:.*(claude|anthropic)|generated with|^claude-session:' # trailers, want 0
gh api repos/OWNER/REPO/contributors --jq '.[].login'                 # want only John-ODell
```

## Clean the old history

This is the one history rewrite the skill allows. It keeps every commit,
tree, author date and committer date, and only (a) deletes the
`Co-Authored-By`, `Generated with` and `Claude-Session` lines from messages
and (b) renames the author and committer on commits that were made as
Claude to John. Tested 2026-10-17 on a local mirror of wordell: 119 commits
in, 119 out, 213 trailer lines and 110 AI author or committer fields to
zero, every date, tree and subject identical, six seconds. Commit hashes change, so it is a
force-push of every branch and tag, and every other clone of the repo must
be reset afterwards.

`scripts/scrub-ai-attribution.sh` does it in three steps on a bare mirror:

```bash
scripts/scrub-ai-attribution.sh audit   OWNER/REPO   # clone a mirror, count, change nothing
scripts/scrub-ai-attribution.sh rewrite OWNER/REPO   # rewrite the mirror, verify dates and trees match
scripts/scrub-ai-attribution.sh push    OWNER/REPO   # publish it (asks for the repo name)
```

`scripts/scrub-pr-bodies.sh OWNER/REPO` then removes the footer from PR and
issue bodies, backing up each original first.

Before `push`, on each repo:

- Stop every session that has the repo checked out, local worktrees
  included. A session that pushes old-history commits after the rewrite
  re-introduces them and makes a mess.
- Note any clone with uncommitted or unpushed work. Commit and push it
  first, or stash it, because the reset afterwards discards it.
- Open PRs survive: their branches are rewritten too, and GitHub keeps the
  PR attached. Merged PRs keep pointing at the old squash hashes; that is
  cosmetic.

After `push`, in every clone:

```bash
git fetch origin && git reset --hard origin/main      # or the branch it is on
```

Then confirm with the three checks above. GitHub rebuilds the Contributors
graph in the background; give it a few minutes.

### What the scrub does not do

- It does not touch commits authored with an unlinked `*.local` address
  unless `FIX_LOCAL_EMAIL=1`. Those commits never counted for John, so
  fixing them would be fair, but they are old and would land about 1,400
  commits on the radar at once, which is the opposite of a bullseye. Leave
  them unless John asks.
- It does not rewrite refs GitHub owns (`refs/pull/*`), so a merged PR's
  "commits" tab can still show old hashes. Nothing counts from there.
- It does not change dates. Backdating is never allowed.

## Verified on this account

- 2026-10-17: `claude` (GitHub user id 81847) is what `noreply@anthropic.com`
  resolves to in the Contributors list. Co-author trailers with that
  address do not add it to Contributors; commits authored with it do.
