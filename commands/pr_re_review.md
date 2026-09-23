# PR Re-Review

## Context
This prompt is for reviewing a pull request after the implementer has applied feedback from one or more reviewers.  
The goal is to verify that all valid comments (including those from other reviewers) are correctly addressed, no new issues are introduced, and any incorrect or conflicting feedback is identified and clarified.

## Preparation
1. Fetch the latest PR state, reviews, and comments:
   - `gh pr view <PR#> --comments --json title,body,headRefName,baseRefName,files,commits,reviews,comments`
2. Understand changes since the previous review:
   - `gh pr diff <PR#>`
   - Optionally use `git log --oneline` and `git diff` to compare against the last reviewed commit
3. Re-check related issues and documentation:
   - `gh issue view <id>`
   - README, design docs, and `rg` for existing patterns and conventions
4. Check CI and test status:
   - `gh run list --limit 5`
   - Run the project's standard test commands locally when appropriate

## Re-Review Focus
Focus on differences since the previous review while considering feedback from all reviewers:

- **Mapping to review comments**  
  For each review comment (yours and others'), verify that the implementation reflects the intended change. Watch for misinterpretation, unnecessary scope expansion, or partial fixes.

- **Other reviewers' feedback quality**  
  Check whether comments from other reviewers are technically sound and consistent with project conventions. If a comment is incorrect, conflicting, or harmful, call it out respectfully with concrete reasoning and suggest a better approach.

- **Application of others' feedback**  
  Confirm that changes requested by other reviewers have been implemented correctly and completely, without introducing regressions, style inconsistencies, or design drift.

- **New issues introduced**  
  Ensure that the fixes do not introduce new bugs, regressions, performance problems, security risks, or maintainability issues.

- **Consistency and design**  
  Verify that naming, abstractions, and responsibility boundaries remain coherent with the existing architecture. Avoid solutions that satisfy a single comment while degrading overall design.

- **Tests and validation**  
  Check that tests are added or updated where appropriate and that important scenarios pass. Re-run key tests locally when needed.

- **Unresolved feedback**  
  Identify comments that remain open or are intentionally left unresolved; assess whether this is acceptable and add clarification in the PR discussion if needed.

## Output
Post a structured re-review comment using `gh pr comment` with a heredoc to preserve Markdown formatting, for example:

```bash
gh pr comment <PR#> --body "$(cat <<'EOF'
Write the PR re-review result in Markdown here.
EOF
)"
```

- Clearly indicate which review comments (including those from other reviewers) each change addresses, referencing files and lines where helpful.
- Highlight any remaining concerns, incorrect or conflicting feedback, and newly discovered issues.
- If the PR now looks good overall, state that explicitly and, when appropriate, combine this with an "Approve" review.
- Optionally end the comment with `by.Spock`.
