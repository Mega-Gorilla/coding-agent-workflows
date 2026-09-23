# PR Review

## Preparation
1. `gh pr view --json title,body,headRefName,baseRefName,files,commits,reviews,comments`
2. Fetch linked issues, referenced docs: `gh issue view <id>`, README, design docs, `rg` for conventions
3. `gh run list --limit 5`, `git log --oneline HEAD~5..` for CI/commit context

## Review Criteria
Analyze each file/change thoroughly:

- **Issue/PR alignment**: Changes satisfy stated goals, no scope creep
- **Correctness**: Edge cases, error handling, logic soundness
- **Reusability & generalization**: Avoid hardcoding, enable reuse, proper abstraction
- **Declarations & naming**: Consistent with codebase conventions, clear interfaces
- **Cleanup opportunities**: Dead code, redundant logic, simplification potential
- **Maintainability**: Readable, well-structured, documented when non-obvious
- **Tests & validation**: Coverage adequate, run tests via uv/venv/docker when needed

Use `gh pr diff`, `gh pr checkout`, `git diff`, `rg` for inspection.

## Output
Post detailed, organized review in Japanese using `gh pr comment` with a heredoc to preserve Markdown formatting, for example:

```bash
gh pr comment <PR#> --body "$(cat <<'EOF'
ここにPRレビューコメントのMarkdown本文を書く
EOF
)"
```

Include file:line references, test results/evidence, and end with `by.Spock`.
