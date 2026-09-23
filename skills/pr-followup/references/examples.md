# PR follow-up marker examples

Use these examples for structure only. Replace every ID, event ID, and SHA with verified values.

## Partial application

```markdown
## レビュー対応

- [F1] applied: 認可を永続化前へ移動し、未認可ケースのテストを追加しました。
- [F2] not_applied: 提案されたキャッシュはこの経路では共有されず、導入すると一貫性を損なうため適用していません。

### 検証

- `npm test`: 成功

<!-- coding-agent-followup:v1
workflow_id: 6ba7b810-9dad-11d1-80b4-00c04fd430c8
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
workflow_id: 123e4567-e89b-12d3-a456-426614174000
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
workflow_id: 6ba7b810-9dad-11d1-80b4-00c04fd430c8
origin_event_id: none
status: already_resolved
reviewed_head_sha: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
result_head_sha: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
finding_statuses: F1=already_resolved
-->
```

## Blocked

Explain the exact conflict, missing permission, unexpected remote HEAD, or required user decision. Do not claim a `result_head_sha` for a push that did not happen; use the verified current remote HEAD.
