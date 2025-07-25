# CLAUDE.md

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

## Investigation

- You may use Web search to investigate the problem or fetch information as you need.
  ```sh
  gemini -p "WebSearch: ..."
  ```
