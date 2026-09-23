# Claude Code commands から Skills への移行

このリポジトリは、Claude Code の従来形式 `commands/*.md` と、Claude Code・Codexの両方で利用できる `skills/<name>/SKILL.md` を収録しています。

| ワークフロー | Claude Code従来形式 | Claude Code Skill | Codex Skill |
| --- | --- | --- | --- |
| Focused review | `/review` | `/review` | `$review` |
| Review follow-up | `/review_followup` | `/review-followup` | `$review-followup` |
| Detailed PR review | `/pr_review` | `/pr-review` | `$pr-review` |
| PR re-review | `/pr_re_review` | `/pr-re-review` | `$pr-re-review` |
| PR merge | `/pr_merge` | `/pr-merge` | `$pr-merge` |
| Startup status | `/startup_status` | `/startup-status` | `$startup-status` |

Claude Codeの公式資料では `commands/*.md` は引き続き読み込まれますが、「Skillsと同じ仕組みの単一ファイルプロンプト」と説明されています。新規利用には、説明メタデータ、関連ファイル、スクリプトなどを同梱できるSkills形式を推奨します。

Codexでは任意のカスタムスラッシュコマンドを追加するのではなく、Skillsを利用します。名前を指定する場合は `$skill-name`、通常の依頼文ではdescriptionに基づく自動選択が使われます。

## 公式資料

- [OpenAI: Build skills](https://developers.openai.com/plugins/build/skills)
- [Claude Code: Explore the .claude directory](https://code.claude.com/docs/en/claude-directory)
- [Claude Code: Skills](https://code.claude.com/docs/en/skills)

