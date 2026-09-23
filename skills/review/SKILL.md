---
name: review
description: Perform a focused review of the current pull request and produce concise, actionable Japanese findings. Use when the user asks for a focused PR review without a broad implementation task.
---

# Focused PR Review

Review the current pull request against its stated goal and the repository's conventions.

1. Read the PR title, body, branches, files, commits, and reviews with `gh pr view`. Include comments when they affect the review.
2. Inspect linked issues or design documentation and recent CI or commit history only when they provide necessary evidence.
3. Review the diff for correctness, edge cases, error handling, maintainability, naming, dead code, and missing tests or documentation.
4. Use `gh pr diff`, `git diff`, and `rg` for targeted inspection. Run tests when they are needed to establish a finding.
5. Keep review findings evidence-based. Do not invent file or line references.

Return a concise Japanese review ready for a PR comment:

- Order findings by severity.
- Include file paths and line numbers when available.
- State which tests were run or could not be run.
- Give an overall assessment and next steps when useful.
- End with `by.Spock`.

Do not post the review or modify the repository unless the user's request authorizes that action.

