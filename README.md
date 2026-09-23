# Coding Agent Workflows

Claude CodeとCodexで利用できる、GitHub中心の開発ワークフロー集です。現在のPhase 1では、単発のPRレビューとレビュー対応を、共通のmarker protocolを使うSkillsとして提供します。

workflow実行用の独自スクリプトは使用せず、Skillの指示、`references/`、既存の`gh` / `git`で動作します。実際の別リポジトリ開発で評価した後、監視用補助スクリプトが必要かを判断します。

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
| `pr-followup` | レビュー指摘を一度評価し、許可された修正・検証・対応報告を行う |
| `pr-merge` | マージ前確認、マージ、Issue更新を行う |
| `startup-status` | Issue、PR、CI、Git履歴から進捗を確認する |

`pr-review-watch`、`pr-followup-watch`、`pr-review-loop`、`pr-followup-loop`は、Phase 1の実運用評価後に追加予定です。設計と進捗は[親Issue #1](https://github.com/Mega-Gorilla/coding-agent-workflows/issues/1)で管理しています。

## PRの指定

`pr-review`と`pr-followup`は同じ規則で次を受け付けます。

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

## 旧workflowからの移行

通常実行では、旧Claude Code commandsと旧Skillsのpath・SHA-256・移行先を表示するだけで、削除しません。確認後、次の明示optionでtimestamp付きbackupへ移動してから新Skillを導入します。

```powershell
./install.ps1 -MigrateLegacy
```

```bash
./install.sh --migrate-legacy
```

各agent rootの`coding-agent-workflows/install-manifest.json`にpackage version、導入ファイルとhash、実施した移行を記録します。backupからの復元を含む詳細は[移行ガイド](docs/migration.md)を参照してください。

`-LegacyClaudeCommands` / `--legacy-claude-commands`はdeprecatedです。履歴参照用の旧commandsだけを導入し、新しいClaude Code Skillsとは併用しません。

## 権限境界

- `/pr-review 32`または`$pr-review 32`の明示呼び出しは、そのPRへのレビューコメント投稿を許可します。コード変更やpushは許可しません。
- `/pr-followup 32`または`$pr-followup 32`の明示呼び出しは、そのPRに限定した修正、検証、通常のcommit/push、対応報告を許可します。
- 通常文で自動選択された場合は、ユーザーが明示した操作だけを行います。曖昧な場合は下書きまたは評価までで停止します。
- merge、force-push、branch削除、履歴改変は別の明示依頼が必要です。

## Marker protocol

`pr-review`と`pr-followup`は、通常の日本語コメントにHTML comment形式のv1 markerを含めます。

- 同一GitHubアカウントでもmarker種別でreview側とfollow-up側を区別します。
- 完全な40文字のHEAD SHA、共有`workflow_id`、固定finding IDを使用します。
- markerは認証ではなく、branch protectionやrequired reviewを置き換えません。
- 投稿者権限、編集状態、対象HEADを確認できないmarkerは終端判定に使いません。

仕様と例は各Skillの`references/`に同梱されています。

## リポジトリ構成

```text
.
├── skills/
│   ├── pr-review/
│   ├── pr-followup/
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
