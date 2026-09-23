# Coding Agent Workflows

Claude CodeとCodexで利用できる、GitHub中心の開発ワークフロー集です。PRレビュー、レビュー対応、再レビュー、マージ、プロジェクト状況確認を再利用可能なSkillsとして収録しています。

## 対応環境

| 環境 | 推奨形式 | 呼び出し例 |
| --- | --- | --- |
| Codex | `skills/<name>/SKILL.md` | `$pr-review` |
| Claude Code | `skills/<name>/SKILL.md` | `/pr-review` |
| Claude Code（互換用） | `commands/*.md` | `/pr_review` |

Claude Codeの従来コマンドは現時点でもサポートされていますが、公式資料ではSkillsと同じ仕組みの単一ファイル形式と説明されています。このリポジトリでは、クロスエージェントで利用できるSkillsを主形式とします。詳しくは [移行ガイド](docs/migration.md) を参照してください。

## 収録ワークフロー

| Skill | 用途 |
| --- | --- |
| `review` | 現在のPRを簡潔にレビューする |
| `review-followup` | レビュー指摘を評価し、妥当な修正と報告を行う |
| `pr-review` | PRを詳細にレビューする |
| `pr-re-review` | 修正後のPRを再レビューする |
| `pr-merge` | マージ前確認、マージ、Issue更新を行う |
| `startup-status` | Issue、PR、CI、Git履歴から進捗を確認する |

## 必要なもの

- [Claude Code](https://code.claude.com/docs/en/overview) または Codex
- [GitHub CLI (`gh`)](https://cli.github.com/)
- `git`
- GitHub CLIの認証（`gh auth login`）

## インストール

### PowerShell

```powershell
git clone https://github.com/Mega-Gorilla/coding-agent-workflows.git
cd coding-agent-workflows
./install.ps1
```

既定ではClaude CodeとCodexの両方へSkillsをインストールします。片方だけの場合は `-Target claude` または `-Target codex` を指定してください。

```powershell
./install.ps1 -Target codex
./install.ps1 -Target claude
```

Claude Codeの従来コマンド名も導入する場合：

```powershell
./install.ps1 -Target claude -LegacyClaudeCommands
```

既存ファイルは既定で上書きしません。確認後に更新するときだけ `-Force` を加えてください。

### macOS / Linux

```bash
git clone https://github.com/Mega-Gorilla/coding-agent-workflows.git
cd coding-agent-workflows
./install.sh
```

使用例：

```bash
./install.sh --target codex
./install.sh --target claude --legacy-claude-commands
./install.sh --force
```

## 注意事項

- SkillsはGitHub CLIを使ってPRやIssueを読み書きします。レビューの投稿、コード変更、マージなどは、依頼された範囲に限って実行します。
- `skills/pr-merge` のsignage通知は任意です。ローカルに対応Skillが設定されている場合だけ利用します。
- 互換用 `commands/pr_merge.md` は元環境の `signage-notify` を必須とする原文を保持しています。他環境で使う場合はSkills版を推奨します。
- `by.Spock` と `by.Scotty` はレビュー担当と実装担当を識別する署名です。不要なら各Skillを調整してください。

## リポジトリ構成

```text
.
├── skills/          # Claude Code・Codex共通の推奨形式
├── commands/        # Claude Code従来形式（互換用）
├── docs/            # 移行・利用資料
├── install.ps1      # Windows用インストーラー
├── install.sh       # macOS / Linux用インストーラー
└── LICENSE          # MIT License
```

## License

[MIT](LICENSE)

