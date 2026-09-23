---
name: review-followup
description: Evaluate PR review feedback, implement the valid parts, validate the fixes, and report the outcome in Japanese. Use when the user asks to address review comments on an existing pull request.
---

# Review Follow-Up

Act as the implementer responding to review feedback. Assess every actionable comment rather than applying suggestions blindly.

1. Fetch the PR, reviews, comments, files, commits, and body with `gh pr view`.
2. Build one consolidated checklist of actionable feedback from all reviewers.
3. Gather evidence from the diff, git history, linked issues, documentation, tests, and existing repository patterns as needed.
4. Classify each item as valid, partially valid, or invalid/inappropriate. For rejected or adjusted suggestions, keep a concrete technical rationale.
5. Implement only the valid portions with minimal, focused changes. Avoid unrelated refactors.
6. Run the relevant tests and checks. Add or update tests when required to validate critical behavior within scope.
7. Revisit the checklist so no review item is silently dropped.

When authorized to update the PR, post one comprehensive Japanese follow-up comment that maps every item to fixed, partially fixed, or not applied; explains important decisions; references files and lines where useful; lists test results; and calls out remaining trade-offs. End the comment with `by.Scotty`.

Use a file or another shell-safe mechanism for multiline Markdown when calling `gh pr comment`; do not interpolate untrusted review text into executable shell syntax. Stop and report unresolved conflicts between review comments or requirements.

