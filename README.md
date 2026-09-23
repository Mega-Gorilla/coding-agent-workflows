# Claude Code Custom Commands

Claude Code で使用しているカスタムスラッシュコマンドをまとめたリポジトリです。
PR のレビュー、レビュー対応、マージ、作業状況の確認を支援します。

## 収録コマンド

| コマンド | ファイル | 用途 |
| --- | --- | --- |
| `/review` | `commands/review.md` | 現在の PR を簡潔にレビューする |
| `/review_followup` | `commands/review_followup.md` | レビュー指摘を評価し、妥当な修正と報告を行う |
| `/pr_review` | `commands/pr_review.md` | PR を詳細にレビューして日本語コメントを作成する |
| `/pr_re_review` | `commands/pr_re_review.md` | 修正後の PR を再レビューする |
| `/pr_merge` | `commands/pr_merge.md` | マージ前確認、マージ、Issue 更新を行う |
| `/startup_status` | `commands/startup_status.md` | Issue、PR、CI、Git 履歴から進捗を確認する |

## 必要なもの

- [Claude Code](https://code.claude.com/docs/en/overview)
- [GitHub CLI (`gh`)](https://cli.github.com/)
- 対象リポジトリで利用できる `git`
- GitHub CLI の認証（`gh auth login`）

## インストール

### PowerShell

```powershell
git clone <REPOSITORY_URL>
cd claude-code-custom-commands
./install.ps1
```

既存の同名コマンドは上書きしません。内容を確認して上書きする場合だけ、次を実行します。

```powershell
./install.ps1 -Force
```

### macOS / Linux

```bash
git clone <REPOSITORY_URL>
cd claude-code-custom-commands
./install.sh
```

既存の同名コマンドを上書きする場合は `./install.sh --force` を使います。

手動で導入する場合は、`commands/*.md` を `~/.claude/commands/` へコピーしてください。ファイル名から `.md` を除いた文字列がスラッシュコマンド名になります。配置場所については [Claude Code の `.claude` ディレクトリ資料](https://code.claude.com/docs/en/claude-directory) も参照してください。

## 注意事項

- コマンドは GitHub CLI を使って PR や Issue を読み書きします。実行前に対象リポジトリと操作内容を確認してください。
- `/pr_merge` は、元の利用環境に合わせて `signage-notify` スキルによる LG signage 通知を必須としています。このスキルを利用しない環境では、`commands/pr_merge.md` の「Signage notification」節を削除または環境に合わせて変更してください。
- `by.Spock` と `by.Scotty` は、レビュー担当と実装担当を識別するための署名です。不要であれば各コマンドから削除してください。
- コマンド本文はプロジェクト固有の規約より優先されるものではありません。対象リポジトリの `CLAUDE.md` や開発ガイドにも従ってください。

## リポジトリ構成

```text
.
├── commands/       # Claude Code のカスタムコマンド
├── install.ps1     # Windows 用インストーラー
├── install.sh      # macOS / Linux 用インストーラー
└── README.md
```

## 公開前チェック

- README 内の `<REPOSITORY_URL>` を実際の GitHub URL に置き換える
- 公開条件に合う `LICENSE` を追加する
- 個人環境向けの署名と signage 通知を残すか決める
- GitHub 上でリポジトリの説明とトピックを設定する
