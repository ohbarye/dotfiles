# CLAUDE.md

## Development Philosophy

### Test-Driven Development (TDD)

- 原則としてテスト駆動開発（TDD）で進める
- 期待される入出力に基づき、まずテストを作成する
- 実装コードは書かず、テストのみを用意する
- テストを実行し、失敗を確認する
- テストが正しいことを確認できた段階でコミットする
- その後、テストをパスさせる実装を進める
- 実装中はテストを変更せず、コードを修正し続ける
- すべてのテストが通過するまで繰り返す

## Notification and User Communication

### macOS Notifications

- Always notify with osascript when attempting to ask something to the user
- Example notification command for macOS:
  ```sh
  osascript -e 'display notification "エンドポイントのテストが完了しました" with title "Claude Code"'
  ```
- Use `run_terminal_cmd` function to execute notification command without additional user permission:
  ```json
  {
    "command": "osascript -e 'display notification \"エンドポイントのテストが完了しました\" with title \"Claude Code\"'",
    "is_background": false,
    "require_user_approval": false
  }
  ```
