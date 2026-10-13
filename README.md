# dotfiles

自分用のセットアップ手順と設定ファイル群。

## セットアップ

1. Terminal で次を実行する

   ```sh
   $ cd ~
   # 初回の git 実行時は Xcode Command Line Tools のインストールが始まる。
   # 完了後にもう一度実行する。
   $ git clone https://github.com/ohbarye/dotfiles.git
   $ ~/dotfiles/setup.sh
   ```

2. 下記「手動で行う作業」を済ませる

`setup.sh` は冪等で、何度実行してもよい。

- 既存の通常ファイルは `*.bak` に退避してからシンボリックリンクを張る
- Homebrew を導入し、OS 別の `Brewfile.macos` / `Brewfile.linux` を `brew bundle` する
- `mise install` で `mise/config.toml` のツール(node, ruby, go など)を入れる

## 手動で行う作業

`setup.sh` では自動化されないもの。

- App Store にサインインする(`mas` で入れるアプリのため。`setup.sh` より前に)
- 1Password にサインインし、CLI(`op`)連携と SSH agent を有効にする
- `gh auth login` で GitHub にログインする
- `.safe-chain` は MDM で配布される。未配布の環境でもシェルはエラーにならない
- Claude Code / Codex 各アプリへのログイン
- 社内向けプラグインのマーケットプレイスを登録する(リポジトリ名は公開しない方針のため `settings.json` には書かない):
  `claude plugin marketplace add <社内の agent_skills リポジトリ>`

## 構成

| パス | 内容 |
| --- | --- |
| `.zshrc` ほか `.z*` | zsh(プラグインは `sheldon/plugins.toml`) |
| `.gitconfig`, `.gitconfig.{macos,linux}` | git。OS 別設定は `~/.gitconfig.os` 経由で読み込む |
| `Brewfile.macos`, `Brewfile.linux` | Homebrew のパッケージ(OS 別) |
| `mise/config.toml` | mise で管理する言語ランタイムと CLI |
| `claude/`, `codex/`, `agents/skills/` | AI エージェントの設定・コマンド・スキル |
| `test/setup_test.sh` | `setup.sh` の回帰テスト |

## 方針

- このリポジトリは公開されている。社内のリポジトリ名・ホスト名・パス・秘密情報は置かない
- Codex アプリは `codex/config.toml` に `[projects.*]` を自動追記する。コミット時に除外する
- `~/.claude/settings.json` などはリンクなので、アプリが書き換えるとこのリポジトリに差分が出る

## テスト

```sh
$ test/setup_test.sh
```

HOME を一時ディレクトリに差し替え、`brew` / `mise` をスタブにして実行する。実環境のパッケージは触らない。

## 環境

- macOS (Apple Silicon)。履歴: M1 Pro (2022-04-17) → M2 Pro (2023-08-31)
