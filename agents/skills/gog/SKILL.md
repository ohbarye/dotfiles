---
name: gog
description: Google Workspace操作（Gmail, Calendar, Drive, Docs, Sheets, Chat, Tasks, Contacts）。ユーザーが「メール確認して」「予定を見せて」「ドライブで検索」「ドキュメント作成」「スプレッドシート読んで」「タスク追加」「連絡先検索」などと言ったときに使用。gog CLIを利用してGoogle Workspaceの各サービスを操作する。
---

# gog — Google Workspace CLI Skill

`gog` CLI を使って Google Workspace（Gmail / Calendar / Drive / Docs / Sheets / Chat / Tasks / Contacts）を操作する。

## 前提

- `gog` CLI がインストール済みであること（`brew install gogcli/tap/gog`）
- リポジトリ: https://github.com/chrisbirster/gog
- 対象アカウントが認証済みであること（`gog auth list` で確認）

## 共通ルール

### アカウント指定

1. `gog auth list` で認証済みアカウントを確認する
2. 複数アカウントがある場合はユーザーに確認する
3. すべてのコマンドに `-a <account>` を付与する

### 出力形式

- スクリプト処理やデータ抽出が必要な場合: `-j`（JSON）
- 人間向け表示: `-p`（plain TSV）またはデフォルト出力
- メール本文など長文テキストの取得: `-p` で取得し必要に応じてパイプ処理

### 認証エラー時

トークン期限切れ（`invalid_grant`）が発生したら:
1. ユーザーに `gog auth add <account> --services <service>` の実行を案内する
2. ブラウザ認証が必要なため、自動リトライはしない

### 破壊的操作の確認

メール送信、イベント削除、ファイル削除、タスク完了など変更を伴う操作は、実行前に必ずユーザーに確認する。`--dry-run` でプレビューすることを推奨。

## サービス別リファレンス

詳細は `references/` ディレクトリを参照:

- `references/gmail.md` — Gmail操作（検索、閲覧、送信、ラベル管理）
- `references/calendar.md` — Calendar操作（予定一覧、作成、更新、空き時間確認）
- `references/drive.md` — Drive操作（ファイル検索、ダウンロード、アップロード、共有）
- `references/docs-sheets.md` — Docs / Sheets操作（閲覧、作成、編集）
- `references/other.md` — Chat / Tasks / Contacts操作

## 典型的なワークフロー

### メール確認

```bash
gog auth list
gog gmail ls "in:inbox" -a <account> --max 20 -j
gog gmail read <threadId> -a <account> -p
```

### 今日の予定確認

```bash
gog calendar events -a <account> --from today --to today -j
```

### ファイル検索・ダウンロード

```bash
gog drive search "<query>" -a <account> -j
gog drive download <fileId> -a <account>
```

### メール送信

```bash
# 必ず --dry-run で確認してからユーザーの許可を得て実行
gog gmail send -a <account> --to "<to>" --subject "<subject>" --body "<body>" --dry-run
gog gmail send -a <account> --to "<to>" --subject "<subject>" --body "<body>"
```
