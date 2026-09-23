# PR follow-up marker examples

Use these examples for structure only. Replace every ID, event ID, and SHA with verified values. Generate each new workflow UUID with a runtime facility such as `[guid]::NewGuid()` or `uuidgen`; never copy a literal UUID from this file.

## Partial application

```markdown
## レビュー対応

- [F1] applied: 認可を永続化前へ移動し、未認可ケースのテストを追加しました。
- [F2] not_applied: 提案されたキャッシュはこの経路では共有されず、導入すると一貫性を損なうため適用していません。

### 検証

- `npm test`: 成功

<!-- coding-agent-followup:v1
workflow_id: 8184d466-b09a-4b9b-9f58-dc2932be6877
origin_event_id: none
status: partially_applied
reviewed_head_sha: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
result_head_sha: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
finding_statuses: F1=applied,F2=not_applied
-->

by.Scotty
```

## Human feedback without a review marker

Create a workflow only for the concrete event being handled:

```html
<!-- coding-agent-followup:v1
workflow_id: b4b13e84-67ad-4e18-9bd9-22479fc786db
origin_event_id: 987654321
status: applied
reviewed_head_sha: cccccccccccccccccccccccccccccccccccccccc
result_head_sha: dddddddddddddddddddddddddddddddddddddddd
finding_statuses: none
-->
```

## Already resolved

When current code already resolves every relevant structured finding, preserve the IDs:

```html
<!-- coding-agent-followup:v1
workflow_id: 8184d466-b09a-4b9b-9f58-dc2932be6877
origin_event_id: none
status: already_resolved
reviewed_head_sha: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
result_head_sha: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
finding_statuses: F1=already_resolved
-->
```

## Feedback for an old HEAD

Old-HEAD feedback remains actionable evidence but cannot terminate the current workflow. State what changed between the reviewed SHA and the current result SHA. For example, if `F1` was already fixed by an intervening commit, retain the original reviewed SHA, report the verified current remote HEAD, and use `already_resolved`:

```html
<!-- coding-agent-followup:v1
workflow_id: 8184d466-b09a-4b9b-9f58-dc2932be6877
origin_event_id: none
status: already_resolved
reviewed_head_sha: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
result_head_sha: cccccccccccccccccccccccccccccccccccccccc
finding_statuses: F1=already_resolved
-->
```

Do not copy the old review SHA into `result_head_sha`, and do not discard the finding merely because the PR HEAD advanced.

## Blocked

Explain the exact conflict, missing permission, unexpected remote HEAD, or required user decision. Do not claim a `result_head_sha` for a push that did not happen; use the verified current remote HEAD.
