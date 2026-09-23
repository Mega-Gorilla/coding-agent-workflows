# 旧Claude Code commands／旧Skillsからの移行

このリポジトリは、Claude CodeとCodexで同じ名前を使うSkillsを主形式とします。旧`commands/*.md`は通常配布から外し、履歴参照用に`legacy/claude-commands/`へ移しました。

## 名前の対応

| 旧形式 | 新Skill |
| --- | --- |
| Claude Code `/review`、Codex `$review` | `pr-review` |
| Claude Code `/pr_review`、旧`/pr-review`、Codex旧`$pr-review` | 新しい`pr-review` |
| `/pr_re_review`、`pr-re-review` | `pr-review`の再レビュー動作へ統合 |
| `/review_followup`、`review-followup` | `pr-followup` |
| `pr_merge.md`、`pr-merge` | `pr-merge` |
| `startup_status.md`、`startup-status` | `startup-status` |

Claude Codeの`/review`は組み込みの`code-review` aliasが優先されるため、新しいSkill名には採用しません。

## 移行対象

インストーラーは次を確認します。

- Claude Codeの`commands/`: `review.md`、`pr_review.md`、`pr_re_review.md`、`review_followup.md`、`pr_merge.md`、`startup_status.md`
- Claude Codeの`skills/`: 旧`review`、`pr-review`、`pr-re-review`、`review-followup`、`pr-merge`、`startup-status`
- Codexの`skills/`: 同じ旧Skill一式

現在のpackageと内容が一致するSkillはlegacyとして扱いません。

## 1. Dry-run確認

通常のインストールを実行します。

```powershell
./install.ps1
```

```bash
./install.sh
```

検出した旧ファイルごとにpath、SHA-256、移行先を表示します。この段階では旧ファイルを削除・移動しません。同名の旧`pr-review`などが存在する場合、新Skillは保護のためskipされます。

## 2. Backup付き移行

一覧を確認した後、明示optionを指定します。

```powershell
./install.ps1 -MigrateLegacy
```

```bash
./install.sh --migrate-legacy
```

旧ファイルはagent root内の次の場所へ移動されます。

```text
coding-agent-workflows/backups/YYYYMMDD-HHMMSS/
├── commands/
└── skills/
```

元の相対pathを保持するため、必要なファイルを元の`commands/`または`skills/`へ戻せます。移行後、新しいSkillsが導入されます。

## Manifest

各agent rootに次を作成します。

```text
coding-agent-workflows/install-manifest.json
```

記録内容:

- package version
- インストール日時
- 管理対象ファイルとSHA-256
- 今回の移行元、backup先、旧hash、移行先Skill

次回の通常更新では、manifest記録時から変更されていない管理対象Skillだけを安全に更新します。ユーザー変更済みまたは未管理の同名Skillはskipします。内容を確認して上書きする場合だけ`-Force` / `--force`を使用してください。

## 旧commandsを残す場合

`-LegacyClaudeCommands` / `--legacy-claude-commands`はdeprecatedですが、履歴検証用に残しています。このmodeは旧commandsのみをClaude Codeへ導入し、新しいClaude Code workflow Skillsとは併用しません。

通常利用では新Skillsへ移行してください。

## 公式資料

- [OpenAI: Build skills](https://developers.openai.com/plugins/build/skills)
- [Claude Code: Skills](https://code.claude.com/docs/en/skills)
