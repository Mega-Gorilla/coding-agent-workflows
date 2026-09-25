# PR cleanup report examples

Use these examples for structure only. Replace every ID, SHA, path, and command with verified values.

## Cleaned

```markdown
## PRクリーンアップ結果

対象: PR #32、HEAD `aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa` → `bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb`
確認範囲: `origin/main...HEAD` の差分（5ファイル）と作業ツリー（untracked 2件）

| ID | 分類 | 結果 | 内容 |
| --- | --- | --- | --- |
| C1 | 必須cleanup | cleaned | `src/sync.ts:41` のdebug出力を削除 |
| C2 | 必須cleanup | cleaned | 試行錯誤で残った `scripts/tmp-migrate.sh` を削除（参照なし、本PRで追加、再生成不要） |
| C3 | 意図された構造 | kept_intended | `src/legacy/` の互換層は `docs/compat.md` で維持が要求されている |

### 削除したpath

- `scripts/tmp-migrate.sh`: 本PRのcommit `ccccccc` で追加された一時scriptで、参照がない。再生成は不要。

### 検証

- `npm test -- sync`: 成功
- `npm run lint`: 成功

次は `pr-review` で新しいHEAD `bbbbbbb` をレビューしてください。

<!-- coding-agent-cleanup:v1
status: cleaned
before_head_sha: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
after_head_sha: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cleanup_items: C1=cleaned,C2=cleaned,C3=kept_intended
-->

by.Scotty
```

## Needs decision

An untracked directory of unknown ownership and a public API rename stay untouched:

```html
<!-- coding-agent-cleanup:v1
status: needs_decision
before_head_sha: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
after_head_sha: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
cleanup_items: C1=needs_decision,C2=needs_decision,C3=out_of_scope
-->
```

Explain in the visible report why each `needs_decision` item cannot be changed automatically. Examples: `local-data/` is untracked and its ownership cannot be determined; renaming `exportReport()` changes a public API.

## Partially cleaned

A behavior-preserving refactor that lacks test coverage is deferred:

```html
<!-- coding-agent-cleanup:v1
status: partially_cleaned
before_head_sha: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
after_head_sha: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cleanup_items: C1=cleaned,C2=deferred
-->
```

`partially_cleaned` is not success and does not permit merge. State the reason for every `deferred` item.

## Clean

When no cleanup candidate exists, do not commit and do not post. Report to the user only, for example: "PR #32で新たに導入された技術負債は見つかりませんでした（確認範囲: …）。"
