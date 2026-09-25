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

Codexの旧custom promptsは`/prompts:pr_review`のように呼び出されます。`prompts/pr_review.md`、`prompts/pr_re_review.md`、`prompts/review_followup.md`、`prompts/pr_merge.md`、`prompts/startup_status.md`も上表と同じ新Skillへ移行します。

`pr-review-watch`、`pr-followup-watch`、`pr-review-loop`、`pr-followup-loop`には旧形式がなく、package 0.3.0以降の通常更新で追加されます。4つは明示呼び出し専用で、対応する単発Skillも同時に必要です。

`pr-cleanup`にも旧形式はなく、package 0.4.0以降の通常更新で他のSkillと同様に追加されます。移行対象の旧ファイルはありません。

Claude Codeの`/review`は組み込みの`code-review` aliasが優先されるため、新しいSkill名には採用しません。

## 移行対象

インストーラーは次を確認します。

- Claude Codeの`commands/`: `review.md`、`pr_review.md`、`pr_re_review.md`、`review_followup.md`、`pr_merge.md`、`startup_status.md`
- Claude Codeの`skills/`: 旧`review`、`pr-review`、`pr-re-review`、`review-followup`、`pr-merge`、`startup-status`
- Codexの`prompts/`: `pr_review.md`、`pr_re_review.md`、`review_followup.md`、`pr_merge.md`、`startup_status.md`
- Codexの`skills/`: 同じ旧Skill一式

現在のpackageと内容が一致するSkillはlegacyとして扱いません。

## 1. Dry-run確認

何も変更しないdry-runで、移行を含めた予定操作を確認します。

```powershell
./install.ps1 -MigrateLegacy -WhatIf
```

```bash
./install.sh --migrate-legacy --dry-run
```

検出した旧ファイルごとにpath、SHA-256、移行先と予定backup先を表示し、導入・更新・skipされるSkillを`Would ...`として表示します。dry-runではbackup、Skill、manifestを含め、agent root内のファイルを一切作成・変更・移動しません。

通常実行（`-WhatIf` / `--dry-run`なし、`-MigrateLegacy` / `--migrate-legacy`なし）でも旧ファイルは削除・移動しませんが、新Skillの導入・更新とmanifestの書き込みは行われます。同名の旧`pr-review`などが存在する場合、新Skillは保護のためskipされます。

## 2. Backup付き移行

一覧を確認した後、dry-runを外して明示optionを指定します。

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
├── prompts/
└── skills/
```

元の相対pathを保持するため、必要なファイルを元の`commands/`、`prompts/`、または`skills/`へ戻せます。移行後、新しいSkillsが導入されます。

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

`-Force` / `--force`はlegacy移行の確認を省略しません。旧Skillとして検出された同名pathを置き換える場合は、必ず`-MigrateLegacy` / `--migrate-legacy`でbackupを作成してください。

### Package versionの確認

インストーラーは変更を始める前に、対象となる全agent rootのmanifestの`packageVersion`と、実行するpackageの`VERSION`を比較します。packageの方が古い場合、またはmanifestが存在するのに`packageVersion`を読めない場合（欠落・空・形式不正・読取失敗）は、どのagent rootも変更せずに停止します。manifestが存在しないagent rootは新規導入として扱います。

既存manifestは、バージョン比較の前に「管理記録を安全に読んで保持できるか」も確認します。両インストーラーは、自身が書き出す行形式（先頭が`{`、末尾が`}`、`packageVersion`・`files`・`migrations`が各1回、それ以外はファイル記録と移行記録の行だけ）に一致しないmanifestを停止対象にします。PowerShell版はさらにJSONとして読めることも必須にします。途中に不明な行がある、末尾にゴミがある、途中で切れているmanifestは、`packageVersion`の行を読めても停止します。`-AllowDowngrade` / `--allow-downgrade`で続行した場合、そのmanifestの管理記録は失われる可能性があります。

`VERSION`とmanifestの`packageVersion`は、1〜4個のドット区切り数値要素（各1〜9桁のASCII数字）だけを受け付けます。PowerShell版とPOSIX版は同じ規則で判定し、packageの`VERSION`が不正な場合は`-AllowDowngrade` / `--allow-downgrade`があっても常に停止します。

- 古いcheckoutや別worktreeのインストーラーを誤って実行しても、新しいSkillは巻き戻らず、manifestも書き換わりません。
- 意図して古いpackageへ戻す場合だけ、内容を確認してから`-AllowDowngrade` / `--allow-downgrade`を指定します。
- 実行したpackageに含まれない管理対象Skillのmanifest記録は、そのディレクトリが残っている限り保持します。後で新しいpackageを導入すると、通常の管理対象Skillとして更新されます。

## 旧commandsを残す場合

`-LegacyClaudeCommands` / `--legacy-claude-commands`はdeprecatedですが、履歴検証用に残しています。このmodeは旧commandsのみをClaude Codeへ導入し、新しいClaude Code workflow Skillsとは併用しません。

通常利用では新Skillsへ移行してください。

## 公式資料

- [OpenAI: Build skills](https://developers.openai.com/plugins/build/skills)
- [Claude Code: Skills](https://code.claude.com/docs/en/skills)
