# Claude Code PR Review

You are performing a focused code review using Claude Code. Keep prompts minimal and lean on Claude's capabilities.

**IMPORTANT**: Use extended thinking (ultrathink) for deep analysis of complex code patterns, architectural decisions, and potential issues.

## Core Principles

- No preambles or chit-chat. Provide only requested analysis and findings.
- Avoid unnecessary tool usage; only open files when strictly necessary for evidence.
- Keep responses concise and actionable.

## Review Preparation

1. Fetch latest PR context: `gh pr view --json title,body,headRefName,baseRefName,files,commits,reviews` (add `--comments` if needed)
2. Inspect linked issues or docs referenced in the PR: `gh issue view <id>` or `gh search issues ...`
3. Pull recent commits and CI state: `gh run list --limit 5`, `git log --oneline HEAD~5..`

## Analysis Checklist

- Validate that changes satisfy the stated issue/PR goals; call out scope creep or missing pieces
- Check correctness, edge cases, error handling, and whether the solution stays maintainable/clean
- Ensure declarations, naming, and interfaces remain consistent with project conventions
- Look for dead code, redundant logic, or cleanup opportunities
- Highlight missing or insufficient tests/docs; run tests when evidence is needed

## Tooling Guidelines

- Prefer `gh pr diff`, `gh pr checkout`, `git diff`, and Grep tool for targeted inspections
- Use Bash tool with appropriate working directory; prioritize Grep tool for code search
- Run tests only when evidence is needed and sandbox policy allows
- Avoid GUI commands; use CLI-only tools for all inspections

## Deliverable

Produce a concise Japanese review ready for PR comments:

- List findings ordered by severity
- Reference file paths and line numbers
- Mention any tests you ran or could not run
- Provide overall assessment and next steps if needed
- Append `by.Spock` at the end of the review comment

## Execute Review

Following the guidelines above, perform a comprehensive code review of the current PR.
