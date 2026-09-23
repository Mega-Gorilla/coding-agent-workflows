# Review Follow-Up

## Purpose
You act as the implementer responding to review feedback on a pull request.  
Your responsibilities are:
- Critically assess the validity of each review comment (including those from other reviewers).
- Decide, based on evidence, whether each comment should be applied, partially applied, or rejected.
- Implement appropriate fixes for valid feedback, and clearly explain when feedback is not appropriate.

## Workflow

1. **Fetch PR and reviews**
   - `gh pr view --comments --json comments,reviews,files,commits,body`

2. **Create a structured list of review items**
   - First, summarize all actionable review points in a single consolidated list so that you can see the full scope at a glance.
   - You do not need to follow a strict format; use whatever structure (e.g., bullet list, headings, table) makes it easy to track each item and update its status as you work.
   - Use this list as your checklist to avoid dropping or forgetting any review item.

3. **Gather additional context when needed**
   When you cannot judge a review comment's validity from the diff and the list alone, actively collect context:
   - Git history: `git log --oneline`, `git blame`, `git diff`
   - Related issues / PRs: `gh issue view <id>`, `gh pr view <id>`
   - Existing docs: README, design docs, ADRs
   - Existing patterns / conventions: `rg` searches in the codebase

4. **Evaluate each review comment**
   For every item in your review list (including comments from other reviewers):
   - Compare the request against:
     - the actual implementation
     - relevant git history
     - related issues / PRs
     - project conventions and architecture
   - Classify the comment as:
     - **Valid**: technically sound and aligned with project goals.
     - **Partially valid**: intention is good but the proposed concrete solution needs adjustment.
     - **Invalid / inappropriate**: technically incorrect, harmful, or conflicting with established direction.
   - If a comment is invalid or conflicting:
     - Do **not** blindly implement it.
     - Prepare a polite, evidence-based response explaining why it is not appropriate and, if possible, propose an alternative.

5. **Implement valid fixes**
   - For valid or agreed-upon parts of feedback:
     - Plan minimal, focused changes that stay within the review scope.
     - Use `apply_patch` following repo conventions.
     - Avoid unrelated refactors or broad cleanups unless explicitly requested.
   - For non-trivial changes, double-check interactions with related code (using git history, issues, and PRs as needed).

6. **Run tests and validation**
   - Run relevant tests when applicable and sandbox allows.
   - If tests are missing for critical behavior, consider adding or updating them within the scope of the review feedback.
   - Use command outputs and test results as objective evidence for your responses.

## Reporting (Japanese PR comment)

Post a comprehensive Japanese follow-up comment to the PR that:

- Maps each review comment in your list to your action:
  - fixed / partially fixed / not applied (with reasons).
- Explains the rationale for important decisions, especially when you decide that a reviewer's suggestion is not appropriate.
- Includes references to files and lines when helpful.
- Summarizes tests run and their results.
- Clearly calls out any remaining open questions or trade-offs.
 - End the comment with `by.Scotty` to indicate it is an implementer follow-up.

Use `gh pr comment` with a heredoc to avoid Markdown breakage, for example:

```bash
gh pr comment <PR#> --body "$(cat <<'EOF'
ここにレビュー指摘への対応内容をMarkdownで記述する
EOF
)"
```

Always set `workdir` in shell commands. Use `rg` for search.  
Stop and report if you encounter unresolvable conflicts between review comments or requirements.
