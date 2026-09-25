# Coding Agent Workflows

Claude CodeとCodexで利用できる、GitHub中心の開発ワークフロー集です。PRレビューとレビュー対応を、単発・watch・loopの対称なSkillsと共通marker protocolで提供します。

workflow実行用の独自スクリプトは使用せず、Skillの指示、`references/`、既存の`gh` / `git`で動作します。watch/loopの時間・状態・重複排除もまずscriptlessで実運用し、再現する問題が確認された場合だけ責務を限定した補助スクリプトを検討します。

Phase 1の別repository実PRでの検証と、補助スクリプトを導入しない判断の根拠は[実運用パイロット記録](docs/phase1-pilot.md)にまとめています。

## 対応環境

| 環境 | 形式 | 呼び出し例 |
| --- | --- | --- |
| Codex | `skills/<name>/SKILL.md` | `$pr-review 32` |
| Claude Code | `skills/<name>/SKILL.md` | `/pr-review 32` |

Claude Codeの`/review`は組み込みaliasと衝突するため使用しません。Claude CodeとCodexで同じSkill名を利用します。

## 収録ワークフロー

| Skill | 用途 |
| --- | --- |
| `pr-review` | PRを一度レビューする。過去markerがあれば再レビューとして動作する |
| `pr-review-watch` | 次のレビュー対象イベントを待ち、最大1回レビューして終了する |
| `pr-review-loop` | 最新HEADの承認または停止条件までレビューと待機を反復する |
| `pr-followup` | レビュー指摘を一度評価し、許可された修正・検証・対応報告を行う |
| `pr-followup-watch` | 次のレビュー指摘を待ち、最大1回対応して終了する |
| `pr-followup-loop` | 最新HEADの承認または停止条件まで対応と待機を反復する |
| `pr-cleanup` | PRが新たに導入した技術負債を棚卸しし、動作を変えない範囲で整理して報告する |
| `pr-merge` | マージ前確認、マージ、Issue更新を行う |
| `startup-status` | Issue、PR、CI、Git履歴から進捗を確認する |

watchは未処理イベントがあれば即時処理し、なければ既定60秒間隔で状態を確認し、1サイクルで終了します。開始直後の1回目の確認は待たずに行い、変化を検出したら追加で待たずに処理します。loopは同じ監視規則を複数サイクルに適用します。どちらも開始から最大30分の絶対期限を維持し、新しいHEADでは対応報告を最大2分待ってからレビューします。

watch/loopは明示呼び出し専用です。Claude Codeでは`disable-model-invocation: true`、Codexでは`agents/openai.yaml`の`policy.allow_implicit_invocation: false`を設定しています。

`pr-cleanup`は、実装またはレビュー対応が一段落した後、最終レビューの前に明示的に実行します。目的はリポジトリ全体の負債解消ではなく、「そのPRで新しく導入された負債」を整理するか、残す理由を明示することです。cleanup後の新しいHEADは`pr-review`でレビューします。各follow-upサイクルへの自動組み込みやmerge前の必須化は、実運用評価（#8）の後に判断します。

## PRの指定

7つのPR workflow Skill（`pr-review*`、`pr-followup*`、`pr-cleanup`）は同じ規則で次を受け付けます。

```text
32
#32
owner/repository#32
https://github.com/owner/repository/pull/32
```

引数を省略した場合は、現在のbranchに対応するPRを一意に解決します。解決できない場合は推測せず停止します。

## 必要なもの

- [Claude Code](https://code.claude.com/docs/en/overview)またはCodex
- [GitHub CLI (`gh`)](https://cli.github.com/)
- `git`
- GitHub CLIの認証（`gh auth login`）

## インストール

### Windows PowerShell 5.1 / PowerShell 7

```powershell
git clone https://github.com/Mega-Gorilla/coding-agent-workflows.git
cd coding-agent-workflows
./install.ps1
```

片方だけへインストールする場合:

```powershell
./install.ps1 -Target codex
./install.ps1 -Target claude
```

### macOS / Linux

```bash
git clone https://github.com/Mega-Gorilla/coding-agent-workflows.git
cd coding-agent-workflows
./install.sh
```

```bash
./install.sh --target codex
./install.sh --target claude
```

既存の管理対象Skillがmanifest記録時から変更されていなければ通常更新されます。未管理またはユーザー変更済みのSkillは保護され、明示的な`-Force` / `--force`なしでは上書きされません。ただし、旧Skillとして検出された同名pathはforceでも上書きされず、backup付きの`-MigrateLegacy` / `--migrate-legacy`が必要です。

### 変更せずに確認する

通常実行は新Skillの導入・更新とmanifestの書き込みを行います。何も変更せずに、検出結果と予定される操作だけを表示するには次を使います。

```powershell
./install.ps1 -WhatIf
./install.ps1 -MigrateLegacy -WhatIf
```

```bash
./install.sh --dry-run
./install.sh --migrate-legacy --dry-run
```

### 古いpackageによる上書き防止

インストール済みmanifestの`packageVersion`より古いpackageでは、どのagent rootも変更せずに停止します。manifestが存在するのに`packageVersion`を読めない場合（欠落・空・形式不正・読取失敗）や、manifest自体が壊れていて管理記録を安全に保持できない場合も同様に停止します。packageの`VERSION`は1〜4個の数値要素（各1〜9桁、例: `0.3.1`）でなければならず、不正な場合は常に停止します。古いcheckoutや別worktreeから誤って実行しても、新しいSkillを巻き戻したり管理対象から外したりしません。意図して戻す場合だけ、内容を確認してから`-AllowDowngrade` / `--allow-downgrade`を指定してください。

また、実行したpackageに含まれない管理対象Skill（ディレクトリが残っているもの）のmanifest記録は削除せずに保持します。

## 旧workflowからの移行

通常実行では、旧Claude Code commands、Codex custom prompts、旧Skillsのpath・SHA-256・移行先を表示するだけで、削除・移動しません（新Skillの導入・更新は行われます）。事前に何も変更せず確認する場合は`-WhatIf` / `--dry-run`を併用してください。確認後、次の明示optionでtimestamp付きbackupへ移動してから新Skillを導入します。

```powershell
./install.ps1 -MigrateLegacy
```

```bash
./install.sh --migrate-legacy
```

各agent rootの`coding-agent-workflows/install-manifest.json`にpackage version、導入ファイルとhash、実施した移行を記録します。backupからの復元を含む詳細は[移行ガイド](docs/migration.md)を参照してください。

`-LegacyClaudeCommands` / `--legacy-claude-commands`はdeprecatedです。履歴参照用の旧commandsだけを導入し、新しいClaude Code Skillsとは併用しません。

## 権限境界

- ユーザーの最新メッセージ自体が`/pr-review 32`または`$pr-review 32`形式の呼び出しであれば、そのPRへのレビューコメント投稿を許可します。コード変更やpushは許可しません。
- ユーザーの最新メッセージ自体が`/pr-cleanup 32`または`$pr-cleanup 32`形式の呼び出しであれば、そのPRに限定した動作を変えないcleanup・refactor、安全性を確認できた不要ファイルの削除、検証、通常のcommit/push、cleanup報告を許可します。PRと無関係な既存負債の修正、公開API・永続データ形式・外部contractの変更、大規模なarchitecture変更、所有者が不明なuntracked fileの削除、dependencyの追加は許可しません。
- ユーザーの最新メッセージ自体が`/pr-followup 32`または`$pr-followup 32`形式の呼び出しであれば、そのPRに限定した修正、検証、通常のcommit/push、対応報告を許可します。
- watch/loopは対応するSkill名を明示して呼び出した場合だけ動作します。review側は投稿だけ、follow-up側は対象PRに限定した修正・検証・通常のcommit/push・対応報告を、最大30分の実行中に反復できます。
- 通常文で自動選択された場合は、ユーザーが明示した操作だけを行います。曖昧な場合は下書きまたは評価までで停止します。
- merge、force-push、branch削除、履歴改変は別の明示依頼が必要です。

## Watch／loopの停止条件

- 最新HEADへの信頼できる`approved`
- `blocked`、PRのclose／merge、キャンセル、認証・権限・安全上の問題
- 開始から30分の絶対期限
- 同じfindingと同じ反論が、新しい証拠なしで2往復した場合

自由形式LGTMはLLMが意味を評価します。ただし、投稿時HEADを安全に結び付けられないコメント、編集済みmarker、古いHEAD、信頼条件を満たさない投稿は終端に使いません。timeoutは承認ではなく「今回の監視時間内に承認を確認できなかった」という結果です。

## Marker protocol

`pr-review`と`pr-followup`は、通常の日本語コメントにHTML comment形式のv1 markerを含めます。

- 同一GitHubアカウントでもmarker種別でreview側とfollow-up側を区別します。
- 完全な40文字のHEAD SHA、共有`workflow_id`、固定finding IDを使用します。
- markerは認証ではなく、branch protectionやrequired reviewを置き換えません。
- 投稿者権限、編集状態、対象HEADを確認できないmarkerは終端判定に使いません。

`pr-cleanup`は別種の`coding-agent-cleanup:v1` markerに、cleanup前後の完全HEAD SHA、status（`cleaned`、`partially_cleaned`、`needs_decision`、`blocked`）、cleanup項目IDごとの結果を記録します。`workflow_id`を持たず、review／follow-upのworkflowを継続・完了させることも、承認として扱われることもありません。cleanup不要（`clean`）の場合は、commitもコメント投稿も行いません。

仕様と例は各Skillの`references/`に同梱されています。

## リポジトリ構成

```text
.
├── skills/
│   ├── pr-review/
│   ├── pr-review-watch/
│   ├── pr-review-loop/
│   ├── pr-followup/
│   ├── pr-followup-watch/
│   ├── pr-followup-loop/
│   ├── pr-cleanup/
│   ├── pr-merge/
│   └── startup-status/
├── legacy/claude-commands/  # 履歴参照用。通常配布対象外
├── docs/
├── VERSION
├── install.ps1
├── install.sh
└── LICENSE
```

## License

[MIT](LICENSE)
