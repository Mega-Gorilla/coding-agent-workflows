# PR cleanup reference

This reference defines what `pr-cleanup` inspects, how it classifies candidates, when it may delete files, and how it reports. It uses the v1 protocol in [protocol.md](protocol.md) for target resolution, trust, instruction authority, safe execution, HEAD rules, and safe posting.

## Scope

Only debt that the target PR newly introduced is in scope. Pre-existing debt is recorded as out of scope and left untouched.

### Files and repository state

- files added or changed by the PR;
- untracked and ignored files in the current working tree;
- artifacts created by builds, tests, generators, or formatters;
- debug logs, patches, temporary Markdown, backups, downloads, and scratch scripts;
- unused fixtures, samples, and configuration files;
- mismatches with `.gitignore` or the documented generation steps.

### Code and design

- unused functions, classes, exports, imports, parameters, and branches;
- duplicated code, validation, or API requests;
- unnecessary wrappers, over-abstraction, and single-purpose intermediate layers;
- needlessly deep folder hierarchies and unclear responsibility splits;
- overly complex control flow and hard-to-maintain large functions;
- clearly inefficient processing, such as needless full scans or repeated I/O;
- inaccurate or stale comments, TODOs, and documentation;
- testability, error-handling, and resource-cleanup problems;
- temporary workarounds or compatibility code introduced within the PR.

Do not remove duplication, generated files, compatibility layers, or folder structure that the repository intentionally requires. Decide intent from trusted base-branch instructions, docs, build configuration, and history.

## Classification

Give every candidate a stable item ID for this report (`C1`, `C2`, and so on) and exactly one category:

| Category | Meaning | Automatic action |
| --- | --- | --- |
| Required cleanup | Debt the PR introduced that has no purpose, such as debug output, a leftover temporary file, or dead code | Clean when authorized and behavior-preserving |
| Recommended refactor | A behavior-preserving improvement to code the PR introduced | Clean when small, scoped, and verifiable; otherwise defer with a reason |
| Intended structure | Something that looks like debt but the repository requires | Keep and cite the evidence |
| Pre-existing or out of scope | Debt that existed before the PR or lies outside it | Leave untouched |
| Needs decision | Architecture, public contract, persistent format, ownership, or deletion that the user must decide | Do not change; ask |

## Item outcomes

Each item gets one outcome:

- `cleaned`: the cleanup was made and validated;
- `deferred`: a required cleanup or recommended refactor was not made, with a stated reason such as size, risk, or missing coverage;
- `kept_intended`: intended structure, kept deliberately;
- `out_of_scope`: pre-existing or unrelated debt, left untouched;
- `needs_decision`: waiting for a user decision;
- `blocked`: could not be handled safely.

The overall status in `SKILL.md` follows from the items: any `blocked` gives `blocked`; otherwise any `needs_decision` gives `needs_decision`; otherwise any `deferred` gives `partially_cleaned`; otherwise at least one `cleaned` gives `cleaned`; otherwise, when every item is `kept_intended` or `out_of_scope` or there are no items, the status is `clean`.

## Deletion safety rules

- Never rely on a bulk `git clean`.
- Being untracked or ignored is not a reason to delete a file.
- Before deleting, confirm the exact path, what created it, whether it can be regenerated, and that nothing references it.
- Only a file created by the current workflow, or one that the build configuration demonstrably regenerates, may become an automatic deletion candidate.
- If ownership is unclear, or the path is outside the repository, a broad directory, a symlink, a submodule, or possibly credentials or local configuration, do not delete it; mark it `needs_decision`.
- Never recursively delete a glob, an unresolved variable, the repository root, or an agent root.
- Delete one validated exact path at a time. After deleting, re-run `git status` and a reference search.
- Report every deleted exact path together with how to regenerate it.

## Cleanup marker

When a report is posted, include exactly one marker:

```html
<!-- coding-agent-cleanup:v1
status: cleaned
before_head_sha: 0000000000000000000000000000000000000000
after_head_sha: 1111111111111111111111111111111111111111
cleanup_items: C1=cleaned,C2=kept_intended
-->
```

- `status`: `cleaned`, `partially_cleaned`, `needs_decision`, or `blocked`. A `clean` result posts no comment and therefore no marker.
- `before_head_sha`: the complete PR HEAD pinned at the start.
- `after_head_sha`: the complete remote PR HEAD after the cleanup. When nothing was pushed, it equals `before_head_sha`. Never claim a push that did not happen.
- `cleanup_items`: comma-separated `Cx=outcome` entries with no duplicate IDs, using the item outcomes above.
- Both SHAs are exactly 40 hexadecimal characters.

### Relationship to review and follow-up markers

- The cleanup marker is a separate marker type. It carries no `workflow_id`, does not continue, complete, or reopen a review workflow, and never counts as approval.
- `pr-review`, `pr-followup`, and the watch/loop Skills control workflows only through `coding-agent-review:v1` and `coding-agent-followup:v1` markers. They treat a cleanup marker and its comment as evidence.
- A cleanup push creates a new HEAD. The next `pr-review` reviews that HEAD normally; cleanup does not replace review.
- The same trust and edit rules as other markers apply before anyone relies on a cleanup marker.

## Report contents

Write the report in Japanese Markdown and include:

- the target PR and the complete before- and after-cleanup HEAD SHAs;
- the diff and working-tree scope that was inspected;
- each item with its ID, category, outcome, and reason;
- every deleted exact path and how to regenerate it;
- items kept as intended structure, with evidence;
- pre-existing debt left out of scope;
- tests, lint, builds, and static analysis actually run, with results;
- checks not run, with reasons;
- remaining risks, user decisions needed, and the instruction to run `pr-review` on the after-cleanup HEAD next.
