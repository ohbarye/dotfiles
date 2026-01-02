# AI Agent Guide

## Development Philosophy

### Test-Driven Development (TDD)

- 原則として Kent Beck や t-wada のテスト駆動開発（TDD）で進める
- 期待される入出力に基づき、まずテストを作成する
- 実装コードは書かず、テストのみを用意する
- テストを実行し、失敗を確認する
- テストが正しいことを確認できた段階でコミットする
- その後、テストをパスさせる実装を進める
- 実装中はテストを変更せず、コードを修正し続ける
- すべてのテストが通過するまで繰り返す

### Package Management

- パッケージ管理は個々のプロジェクトに合わせる
- ただしグローバルにインストールするツールは [`mise`](https://mise.jdx.dev/) を使用する

### GitHub

- `gh` コマンドを使用して GitHub の操作を行う

## Investigation

設計や開発の最中に技術的に詰まったところやわからないところ、解決できないエラーなどがあれば以下の順に試行してください。

1. subagent を用いて調査を行う
2. Web Search tool を用いて調査を行う
