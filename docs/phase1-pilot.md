# Phase 1 cross-repository pilot

実施日: 2026-09-24

Phase 1のscriptless baselineを、このrepositoryとは別の実PRでClaude CodeとCodexの両方から使用した記録です。

## 対象

- PR: [Mega-Gorilla/Crassula-ovata#7](https://github.com/Mega-Gorilla/Crassula-ovata/pull/7)
- review時HEAD: `aecd837045b6594a603ff3216db2761e3e947e0b`
- follow-up後HEAD: `7bb9fb902182145f2f46183805f85898f9623a6e`
- workflow ID: `be18a9e9-ba85-41a8-9e2d-3dd68381670a`

対象は文書変更だけのPRです。reviewはClaude Code、follow-upの評価・修正・検証・push・報告はCodexで実行しました。

## 実行結果

1. Claude Codeから`/pr-review Mega-Gorilla/Crassula-ovata#7`を実行し、[reviewコメント](https://github.com/Mega-Gorilla/Crassula-ovata/pull/7#issuecomment-5805170135)を投稿しました。
2. reviewは文書内のversion・進捗表現の不整合を`F1`として報告し、reviewマーカーを`changes_requested`、`F1=open`として記録しました。
3. Codexの`pr-followup`手順でF1を評価し、detached worktreeで文書を修正、`git diff --check`と旧表現の検索を実施しました。
4. commit `7bb9fb902182145f2f46183805f85898f9623a6e`を通常pushし、[follow-upコメント](https://github.com/Mega-Gorilla/Crassula-ovata/pull/7#issuecomment-5805210761)を投稿しました。
5. follow-upマーカーはClaude Codeが作ったworkflow IDとfinding IDを継承し、reviewed HEADとresult HEADを完全SHAで区別して`F1=applied`を記録しました。
6. コード変更とは別に人間の選択が必要なDR-001の依存方針A/Bが残ったため、follow-up全体は`blocked`として停止しました。これは既知情報を推測で埋めず、人間へ返す期待どおりの停止です。

## PR指定の解決

同じbranchとPRに対し、Skillの正規化規則に沿って次を読み取り検証しました。すべてPR #7、HEAD `7bb9fb902182145f2f46183805f85898f9623a6e`へ解決しました。

| 入力 | 解決方法 | 結果 |
| --- | --- | --- |
| `7` | current repositoryのPR番号 | PR #7 |
| `#7` | `#`を除去してPR番号として解決 | PR #7 |
| `Mega-Gorilla/Crassula-ovata#7` | owner/repositoryと番号へ分離 | PR #7 |
| `https://github.com/Mega-Gorilla/Crassula-ovata/pull/7` | PR URLを直接解決 | PR #7 |
| 引数なし | current branchから`gh pr view`で解決 | PR #7 |

## 信頼・編集・HEAD判定

- 2件のコメントはいずれも投稿者`Mega-Gorilla`、`author_association=OWNER`、repository permission `admin`でした。
- 2件とも`created_at == updated_at`で、パイロット中の編集はありませんでした。
- reviewマーカーは旧HEAD、follow-upマーカーは旧HEADと新HEADを分けて記録しました。reviewの`changes_requested`を新HEADへの終端判断として再利用していません。
- GitHub issue commentのREST IDを個別に取得でき、agent間でマーカー本文の意味やID継承に差はありませんでした。
- 同じイベントの重複処理、findingの対立、marker解析の失敗は発生しませんでした。

## 補助スクリプトの評価

このパイロットで、Claude CodeとCodexは既存の`gh` / `git`、共通protocol、GitHub上のmarkerだけで次を一貫して処理できました。

- 別repositoryのPR解決
- 完全HEAD SHAと新旧HEADの区別
- trusted authorと未編集コメントの確認
- workflow IDと固定finding IDの継承
- detached worktreeでの修正と検証
- 人間判断が必要な場合の`blocked`停止

同種の失敗の反復、agent間の解釈差、安全上重要な判定の不安定さ、同じ回避操作の反復は観測されませんでした。そのためPhase 2とPhase 3も補助スクリプトなしで実装します。時間、状態、重複排除はSkillの共通watch/loop protocolに定義し、GitHubのtyped event IDとmarker履歴を永続的な根拠にします。

この結論は補助スクリプトを永久に禁止するものではありません。watch/loopを別repositoryで実運用し、同種の構造的失敗が複数回再現した場合だけ、責務を時間・状態・marker構文検証へ限定したhelperを再評価します。

## パイロットの限界

- 単一の文書PRでの1 review／1 follow-upです。
- 編集済みmarker、権限不足投稿者、複数workflow、対立2往復は実際には発生していません。protocol上は終端から除外または`blocked`にしますが、watch/loopの実PRパイロットで継続評価します。
- target PRはDR-001の人間判断待ちであり、workflow自体の承認までを示すパイロットではありません。
