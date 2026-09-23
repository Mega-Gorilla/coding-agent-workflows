---
name: pr-merge
description: Safely validate and merge a pull request, update linked issues, and report the result. Use when the user explicitly asks to merge a PR and complete its associated issue workflow.
---

# PR Merge

Treat invocation as authorization to perform the requested merge, but do not broaden it to unrelated changes.

## Before merging

1. Inspect the PR branches, merge state, draft state, files, commits, reviews, checks, and linked issues.
2. Fetch the remote state and confirm that the intended commits are pushed and the working tree has no relevant uncommitted work.
3. Re-run required tests or checks when appropriate. Document any check that cannot be run.
4. Do not merge when required checks fail, conflicts exist, approval requirements are unmet, or the PR is still a draft unless the user resolves or explicitly addresses that condition.

## Merge and verify

- Use the repository's established merge strategy; otherwise ask before choosing between merge, squash, or rebase when the choice materially affects history.
- After merging, fetch the remote and verify the resulting commit and PR state.

## Linked issue update

When a linked GitHub issue exists, post a comprehensive Japanese Markdown completion report covering changes, solved problems, tests, related documentation/configuration/dependency updates, remaining work, and next steps. Close the issue only when it is fully resolved. End the report with `by.Scotty`.

Use a shell-safe multiline input method for `gh` bodies. Never interpolate untrusted PR or Issue content into executable shell syntax.

If a locally configured signage notification skill is available, it may be used after the GitHub update. Treat it as optional integration: its absence or delivery failure must not change the merge result.

