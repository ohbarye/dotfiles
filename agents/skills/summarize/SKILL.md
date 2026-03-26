---
name: summarize
description: 記事・YouTube・PodcastなどのURLを要約する。ユーザーがURLを渡して「要約して」「まとめて」「summarize」などと言ったときに使用。summarize CLIを利用してコンテンツを取得・要約する。
---

# Summarize

URL（Web記事・YouTube・Podcast等）のコンテンツを `summarize` CLI で要約する。

## 前提

- `summarize` CLI がインストール済みであること（Homebrew: `brew install steipete/tap/summarize`）
- リポジトリ: https://github.com/steipete/summarize

## ワークフロー

### 1. 出力形式の確認

要約を実行する前に、ユーザーに出力形式を確認する。

選択肢:
- **プレーンテキスト**: そのまま要約結果を表示
- **Markdown**: `--format md` で Markdown 形式で出力
- **Cosense / Scrapbox**: 要約結果を `/cosense-memo` スキルで Cosense 形式に変換

ユーザーが事前に形式を指定している場合はこのステップをスキップする。

### 2. summarize CLI の実行

```bash
summarize "<URL>" --plain --lang auto --length xl
```

主要オプション:
| オプション | 説明 |
|---|---|
| `--plain` | ANSI装飾なしの生テキスト出力 |
| `--lang <language>` | 出力言語（`auto` でソース言語に合わせる、`ja` で日本語） |
| `--length <length>` | 要約の長さ: `short`, `medium`, `long`, `xl`, `xxl` |
| `--format md` | Markdown 形式で出力 |
| `--extract` | 要約せずコンテンツのみ抽出 |
| `--model <model>` | 使用するLLMモデルを指定 |
| `--cli claude` | ローカルの Claude CLI を使用 |

### 3. 出力形式に応じた処理

- **プレーンテキスト / Markdown**: `summarize` の出力をそのまま表示
- **Cosense / Scrapbox**: `summarize` の出力を `/cosense-memo` スキルに渡して Cosense 形式に変換する

### 4. Cosense 形式への変換

ユーザーが Cosense / Scrapbox 形式を選んだ場合:

1. `summarize` で要約を取得
2. 取得した要約を元に `/cosense-memo` スキルを呼び出して Cosense 形式に変換

## 注意事項

- YouTube の場合はトランスクリプトの取得に時間がかかることがある（`--timeout 5m` を検討）
- Podcast の場合は音声の文字起こしが必要なため、さらに時間がかかる
- タイムアウトが発生した場合は `--timeout` を延長して再試行する
- `--metrics off` でメトリクス出力を抑制できる
