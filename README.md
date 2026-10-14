# dotfiles

自分用のセットアップ手順と設定ファイル群。macOS と Linux(Dev Container 含む)に対応する。
宣言の正本は `mise/config*.toml` で、[`mise bootstrap`](https://mise.jdx.dev/cli/bootstrap.html)(experimental)が適用する。

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

`setup.sh` は冪等で、何度実行してもよい。mise を用意し、`mise bootstrap` を実行する。

- `~/.config/mise/` に設定をリンクし、`MISE_ENV=macos|linux` で OS 別の設定を重ねる
- dotfiles のリンクを作る(置き換え先に通常ファイルがあれば `*.bak` に退避する)
- macOS: Homebrew のパッケージ(brew / cask / mas)を入れ、`defaults` を適用する
- `[tools]` のツールを入れる(言語ランタイム等は macOS のみ。Linux は `delta` `sheldon` `fzf` `jq`)
- Linux: `apt` で `tree` `vim` `silversearcher-ag` などを入れる(失敗しても続行)

リンクだけ張りたい場合: `SETUP_LINKS_ONLY=1 ~/dotfiles/setup.sh`
Dev Container は VS Code の dotfiles 連携が `setup.sh` を実行する。コンテナでは Homebrew を使わない。

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
| `mise/config.toml` | 共通: ツール、dotfiles のリンク(AI エージェント向けは相対リンク) |
| `mise/config.macos.toml` | macOS: パッケージ(brew / cask / mas)、defaults、エディタ・Karabiner |
| `mise/config.linux.toml` | Linux / Dev Container: OS 別の git 設定など |
| `setup.sh` | mise を用意して `mise bootstrap` を呼ぶ起点 |
| `.zshrc` ほか `.z*` | zsh(プラグインは `sheldon/plugins.toml`) |
| `.gitconfig`, `.gitconfig.{macos,linux}` | git。OS 別設定は `~/.gitconfig.os` 経由で読み込む |
| `editors/`, `karabiner/` | VS Code / Cursor / Karabiner の設定と拡張機能の一覧 |
| `claude/`, `codex/`, `agents/skills/` | AI エージェントの設定・コマンド・スキル |
| `test/setup_test.sh` | 回帰テスト |

## 日常の操作

```sh
$ mise bootstrap status            # 宣言と実機の差分
$ mise bootstrap plan              # 適用内容のプレビュー
$ mise bootstrap --dry-run         # 何も書き込まずに確認
$ mise bootstrap                   # 適用(収束型。何度実行してもよい)
$ mise bootstrap packages use brew:foo   # パッケージを宣言に追加してインストール
```

`MISE_ENV` は `.zshenv` が OS から決める。

## 方針

- このリポジトリは公開されている。社内のリポジトリ名・ホスト名・パス・秘密情報は置かない
- Codex アプリは `codex/config.toml` に `[projects.*]` を自動追記する。コミット時に除外する
- `~/.claude/settings.json` などはリンクなので、アプリが書き換えるとこのリポジトリに差分が出る
- `mise bootstrap` は experimental。挙動が変わる可能性があるので、変更時は `--dry-run` で確認する

## テスト

```sh
$ test/setup_test.sh
```

静的チェックに加え、実際の `mise` で dotfiles をサンドボックスの HOME に適用し、全体フローは `brew` / `gh` などをスタブにして確認する。実環境のパッケージや defaults には触れない。

## 環境

- macOS (Apple Silicon)。履歴: M1 Pro (2022-04-17) → M2 Pro (2023-08-31)
