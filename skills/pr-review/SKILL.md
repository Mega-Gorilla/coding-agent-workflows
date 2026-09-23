---
name: pr-review
description: Conduct a detailed pull-request review and post or prepare a structured Japanese review. Use when the user requests a comprehensive PR review with evidence and test coverage assessment.
---

# Detailed PR Review

1. Read the PR title, body, branches, files, commits, reviews, and comments with `gh pr view`.
2. Inspect linked issues, referenced documentation, repository conventions, recent CI, and commit history where relevant.
3. Review every changed file for:
   - alignment with the Issue and PR goal;
   - correctness, edge cases, and error handling;
   - reusable design without unnecessary hardcoding;
   - consistent declarations, names, and interfaces;
   - dead code, redundant logic, and safe simplification opportunities;
   - maintainability and adequate documentation;
   - meaningful tests and validation.
4. Use `gh pr diff`, `git diff`, and `rg` for inspection. Run the project's relevant tests when needed for evidence.

Produce an organized Japanese review with findings ordered by severity, accurate file-and-line references, test results, and an overall assessment. End with `by.Spock`.

Post it with `gh pr comment` only when the user's request authorizes posting. Preserve Markdown through a shell-safe multiline input method and never embed untrusted PR content into executable shell syntax.

