---
name: pr-re-review
description: Re-review a pull request after feedback was addressed, verifying every review item and checking for regressions. Use when the user asks to validate fixes made after one or more PR reviews.
---

# PR Re-Review

1. Fetch the latest PR state, reviews, comments, files, commits, and CI results.
2. Identify the changes made since the previous review and map them to feedback from every reviewer.
3. Verify that each valid comment was addressed correctly and completely. Identify misinterpretations, partial fixes, unnecessary scope expansion, and unresolved feedback.
4. Evaluate whether any feedback was technically incorrect, conflicting, or harmful, and explain that conclusion with evidence.
5. Check the new changes for regressions, security or performance problems, inconsistent design, and missing tests.
6. Run the relevant local tests when appropriate and record the results.

Produce a structured Japanese re-review with clear mappings from feedback to changes, remaining concerns, and newly discovered issues. If the PR is ready, state that explicitly and approve only when the user has authorized submitting a review. End with `by.Spock` when consistent with the repository's review convention.

Use a shell-safe multiline input method for any `gh` comment or review body. Do not interpolate untrusted PR content into executable shell syntax.

