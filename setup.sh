#!/bin/zsh

set -u

# OSを検出
case "$(uname -s)" in
    Linux)
        OS_TYPE="linux"
        BREW_PREFIX="/home/linuxbrew/.linuxbrew"
        ;;
    Darwin)
        OS_TYPE="macos"
        BREW_PREFIX="/opt/homebrew"
        ;;
    *)
        echo "Unsupported OS: $(uname -s)"
        exit 1
        ;;
esac

echo "Detected OS: $OS_TYPE"
echo "Homebrew prefix: $BREW_PREFIX"

# Linux環境での必要パッケージのインストール
if [[ "$OS_TYPE" == "linux" ]] && command -v apt-get >/dev/null 2>&1; then
    echo "Installing Linux desktop integration packages..."

    # パッケージリストの更新
    sudo apt-get update || echo "Warning: Failed to update package list"

    # 必要パッケージのインストール
    sudo apt-get install -y xdg-utils libnotify-bin fzf || echo "Warning: Failed to install some packages"
fi

DOTFILES=( .bash_profile .bashrc .gitconfig .vimrc .vim .bundle .gitignore_global .zlogin .zlogout .zprofile .zshenv .zshrc .ideavimrc .irbrc )

for file in ${DOTFILES[@]}
do
  if [ ! -e "$HOME/$file" ]; then
    ln -s "$HOME/dotfiles/$file" "$HOME/$file"
  elif [ ! -L "$HOME/$file" ]; then
    # ファイルが存在し、シンボリックリンクでない場合はバックアップを作成
    mv "$HOME/$file" "$HOME/$file.bak"
    ln -s "$HOME/dotfiles/$file" "$HOME/$file"
  fi
done

# OS別のgit設定ファイルのシンボリックリンクを作成
case "$OS_TYPE" in
    linux)
        ln -sf "$HOME/dotfiles/.gitconfig.linux" "$HOME/.gitconfig.os"
        ;;
    macos)
        ln -sf "$HOME/dotfiles/.gitconfig.macos" "$HOME/.gitconfig.os"
        ;;
esac

# miseの設定ファイルのシンボリックリンクを作成
mkdir -p "$HOME/.config/mise"
if [ ! -e "$HOME/.config/mise/config.toml" ]; then
  ln -s "$HOME/dotfiles/mise/config.toml" "$HOME/.config/mise/config.toml"
elif [ ! -L "$HOME/.config/mise/config.toml" ]; then
  # ファイルが存在し、シンボリックリンクでない場合はバックアップを作成
  mv "$HOME/.config/mise/config.toml" "$HOME/.config/mise/config.toml.bak"
  ln -s "$HOME/dotfiles/mise/config.toml" "$HOME/.config/mise/config.toml"
fi

# sheldonの設定ファイルのシンボリックリンクを作成
mkdir -p "$HOME/.config/sheldon"
ln -sf "$HOME/dotfiles/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"

# Symlink individual files and directories for AI agents
# これらをDev Containerのコンテナにマウントし、VS Codeのdotfiles連携を使うと参照できないパスへのsymlinkになってしまうため相対パスにする
mkdir -p "$HOME/.agents" "$HOME/.claude" "$HOME/.codex"
ln -sfn ../dotfiles/agents/skills "$HOME/.agents/skills"
ln -sf ../dotfiles/claude/CLAUDE.md "$HOME/.claude/CLAUDE.md"
ln -sf ../dotfiles/claude/settings.json "$HOME/.claude/settings.json"
ln -sfn ../dotfiles/claude/commands "$HOME/.claude/commands"
ln -sfn ../.agents/skills "$HOME/.claude/skills"
ln -sfn ../dotfiles/claude/agents "$HOME/.claude/agents"
ln -sfn ../dotfiles/codex/config.toml "$HOME/.codex/config.toml"
ln -sfn ../dotfiles/codex/AGENTS.md "$HOME/.codex/AGENTS.md"
ln -sfn ../dotfiles/codex/PLANS.md "$HOME/.codex/PLANS.md"
ln -sfn ../.agents/skills "$HOME/.codex/skills"

# macOS のみ: エディタ・Karabiner の設定をリンクする
link_with_backup() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    ln -sfn "$src" "$dst"
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.bak"
    ln -s "$src" "$dst"
  else
    ln -s "$src" "$dst"
  fi
}

if [[ "$OS_TYPE" == "macos" ]]; then
  APP_SUPPORT="$HOME/Library/Application Support"
  link_with_backup "$HOME/dotfiles/editors/vscode/settings.json" "$APP_SUPPORT/Code/User/settings.json"
  link_with_backup "$HOME/dotfiles/editors/vscode/keybindings.json" "$APP_SUPPORT/Code/User/keybindings.json"
  link_with_backup "$HOME/dotfiles/editors/cursor/settings.json" "$APP_SUPPORT/Cursor/User/settings.json"
  link_with_backup "$HOME/dotfiles/editors/cursor/keybindings.json" "$APP_SUPPORT/Cursor/User/keybindings.json"
  link_with_backup "$HOME/dotfiles/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
fi

# リンクだけ張りたい場合: SETUP_LINKS_ONLY=1 ./setup.sh
if [ "${SETUP_LINKS_ONLY:-0}" = "1" ]; then
  echo "SETUP_LINKS_ONLY=1: skipping package installation and system defaults"
  exit 0
fi

# BREW_BIN は外部から上書き可能(テストでスタブを差し込むため)
BREW_BIN="${BREW_BIN:-}"
if [ -z "$BREW_BIN" ]; then
  if command -v brew >/dev/null 2>&1; then
    BREW_BIN="$(command -v brew)"
  elif [ -x "$BREW_PREFIX/bin/brew" ]; then
    BREW_BIN="$BREW_PREFIX/bin/brew"
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    BREW_BIN="$BREW_PREFIX/bin/brew"
  fi
fi
eval "$("$BREW_BIN" shellenv)"
"$BREW_BIN" update

# OS別Brewfileを選択
case "$OS_TYPE" in
    linux)
        BREWFILE="$HOME/dotfiles/Brewfile.linux"
        ;;
    macos)
        BREWFILE="$HOME/dotfiles/Brewfile.macos"
        ;;
    *)
        echo "Unsupported OS for Brewfile: $OS_TYPE"
        exit 1
        ;;
esac

echo "Using Brewfile: $BREWFILE"
"$BREW_BIN" bundle --file "$BREWFILE"

# miseで管理しているツール(node, ruby, go など)をインストール
if command -v mise >/dev/null 2>&1; then
  echo "Installing tools with mise..."
  mise install --yes || echo "Warning: mise install failed"
else
  echo "Warning: mise not found. Run 'mise install' after installing it."
fi

# Cursor の拡張機能をインストール(CLI がある macOS のみ。失敗しても続行)
if [[ "$OS_TYPE" == "macos" ]] && command -v cursor >/dev/null 2>&1; then
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    cursor --install-extension "$ext" || echo "Warning: failed to install Cursor extension $ext"
  done < "$HOME/dotfiles/editors/cursor/extensions.txt"
fi

# macOS のシステム設定を反映
if [[ "$OS_TYPE" == "macos" ]]; then
  "$HOME/dotfiles/macos.sh" || echo "Warning: macos.sh failed"
fi
