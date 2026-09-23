# PR Merge

## Pre-Merge
1. `gh pr view --json headRefName,baseRefName,mergeStateStatus,isDraft,files,commits,reviews`
2. `git fetch origin && git status` — confirm all changes pushed, no local unpushed commits
3. Re-run tests/checks if required; document any skips
4. Verify linked issues open: `gh issue view <id>`

## Merge
- `gh pr merge --merge` (or `--squash`/`--rebase` per repo)
- Verify: `git fetch --all && git log -3 --oneline`

## Issue Update (Japanese, comprehensive, **Markdown**)
The completion report on the linked GitHub issue **must be Markdown**: use H2/H3 headings, tables for file-by-file changes and test results, and fenced code blocks for command output. Never post a plain-text wall. Post it using a heredoc to avoid Markdown breakage, for example:

```bash
gh issue comment <id> --body "$(cat <<'EOF'
ここにIssueへのMarkdown形式のコメント本文を書く
EOF
)"
```

Cover completed changes (file-by-file with purpose), problems solved, test results, related updates (docs/config/deps), project progress (what's done/remains), and next steps. Include command outputs and evidence. End with `by.Scotty`.

Close issue only if fully resolved. Never merge if checks fail or conflicts exist.

## Signage (看板) notification
After the issue update, **always** notify the LG signage via the `signage-notify` skill (`--event task_succeeded`, `--body-format markdown`, `--message-file`). 「看板」 means the signage, not the GitHub issue.
