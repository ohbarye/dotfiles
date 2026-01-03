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
    sudo apt-get install -y xdg-utils libnotify-bin zsh-antigen fzf || echo "Warning: Failed to install some packages"
fi

DOTFILES=( .bash_profile .bashrc .gitconfig .vimrc .vim .bundle .gitignore_global .zlogin .zlogout .zprofile .zshenv .zshrc .ideavimrc .irbrc )

for file in ${DOTFILES[@]}
do
  if [ ! -e $HOME/$file ]; then
    ln -s $HOME/dotfiles/$file $HOME/$file
  elif [ ! -L $HOME/$file ]; then
    # ファイルが存在し、シンボリックリンクでない場合はバックアップを作成
    mv $HOME/$file $HOME/$file.bak
    ln -s $HOME/dotfiles/$file $HOME/$file
  fi
done

# OS別のgit設定ファイルのシンボリックリンクを作成
case "$OS_TYPE" in
    linux)
        ln -sf $HOME/dotfiles/.gitconfig.linux $HOME/.gitconfig.os
        ;;
    macos)
        ln -sf $HOME/dotfiles/.gitconfig.macos $HOME/.gitconfig.os
        ;;
esac

# miseの設定ファイルのシンボリックリンクを作成
mkdir -p $HOME/.config/mise
if [ ! -e $HOME/.config/mise/config.toml ]; then
  ln -s $HOME/dotfiles/mise/config.toml $HOME/.config/mise/config.toml
elif [ ! -L $HOME/.config/mise/config.toml ]; then
  # ファイルが存在し、シンボリックリンクでない場合はバックアップを作成
  mv $HOME/.config/mise/config.toml $HOME/.config/mise/config.toml.bak
  ln -s $HOME/dotfiles/mise/config.toml $HOME/.config/mise/config.toml
fi

# Symlink individual files and directories
ln -sf $HOME/dotfiles/.claude/CLAUDE.md $HOME/.claude/CLAUDE.md
ln -sf $HOME/dotfiles/.claude/settings.json $HOME/.claude/settings.json
ln -sfn $HOME/dotfiles/.claude/commands $HOME/.claude/commands
ln -sfn $HOME/dotfiles/.claude/skills $HOME/.claude/skills
ln -sfn $HOME/dotfiles/.claude/agents $HOME/.claude/agents
ln -sfn $HOME/dotfiles/.codex/config.toml $HOME/.codex/config.toml
ln -sfn $HOME/dotfiles/.codex/AGENTS.md $HOME/.codex/AGENTS.md

if [ ! -e $HOME/dotfiles/antigen.zsh ]; then
  curl -L git.io/antigen > $HOME/dotfiles/antigen.zsh
fi

source $HOME/dotfiles/.zshrc


if [ ! -x "`which brew`" ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$($BREW_PREFIX/bin/brew shellenv)"
brew update

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
brew bundle --file "$BREWFILE"

