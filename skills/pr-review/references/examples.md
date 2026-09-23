# PR review marker examples

Use these examples for structure only. Replace every ID and SHA with verified values.

## Changes requested

```markdown
## レビュー結果

### [F1] 高: 認可前に更新処理が実行される

`src/account.ts:84`では権限確認より先に永続化しています。権限のない呼び出しでも状態が変わるため、更新前に認可を完了してください。

### 検証

- `npm test -- account`: 成功
- 未認可ケースを追加して失敗を再現

判定: changes_requested

<!-- coding-agent-review:v1
workflow_id: 6ba7b810-9dad-11d1-80b4-00c04fd430c8
origin_event_id: none
decision: changes_requested
head_sha: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
finding_statuses: F1=open
-->

by.Spock
```

## Re-review approved

Keep the existing `F1` and mark it resolved:

```markdown
## 再レビュー結果

- [F1] 解決済み: 永続化前に認可され、未認可ケースのテストも追加されています。

判定: approved

<!-- coding-agent-review:v1
workflow_id: 6ba7b810-9dad-11d1-80b4-00c04fd430c8
origin_event_id: none
decision: approved
head_sha: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
finding_statuses: F1=resolved
-->

by.Spock
```

## Comment only

Optional suggestions do not need finding IDs:

```html
<!-- coding-agent-review:v1
workflow_id: 6ba7b810-9dad-11d1-80b4-00c04fd430c8
origin_event_id: none
decision: commented
head_sha: cccccccccccccccccccccccccccccccccccccccc
finding_statuses: none
-->
```

## Blocked

Use `blocked` when the target is known but the result requires user judgment. Explain the conflicting evidence before the marker. Do not post a marker to an unresolved or guessed PR target.
