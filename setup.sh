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

DOT_FILES=( .bash_profile .bashrc .gitconfig .vimrc .vim .bundle .gitignore_global .zlogin .zlogout .zprofile .zshenv .zshrc .ideavimrc .irbrc )

for file in ${DOT_FILES[@]}
do
  if [ ! -e $HOME/$file ]; then
    ln -s $HOME/dotfiles/$file $HOME/$file
  fi
done

# miseの設定ファイルのシンボリックリンクを作成
mkdir -p $HOME/.config/mise
if [ ! -e $HOME/.config/mise/config.toml ]; then
  ln -s $HOME/dotfiles/mise/config.toml $HOME/.config/mise/config.toml
fi

# Config files
mkdir -p $HOME/.config

# Create claude config directory
mkdir -p $HOME/.config/claude

# Symlink individual files and directories
ln -sf $HOME/dotfiles/.claude/CLAUDE.md $HOME/.config/claude/CLAUDE.md
ln -sf $HOME/dotfiles/.claude/settings.json $HOME/.config/claude/settings.json
ln -sfn $HOME/dotfiles/.claude/commands $HOME/.config/claude/commands
# for compatibility
ln -sf $HOME/dotfiles/.claude/CLAUDE.md $HOME/.claude/CLAUDE.md
ln -sf $HOME/dotfiles/.claude/settings.json $HOME/.claude/settings.json
ln -sfn $HOME/dotfiles/.claude/commands $HOME/.claude/commands

if [ ! -e $HOME/dotfiles/antigen.zsh ]; then
  curl -L git.io/antigen > $HOME/dotfiles/antigen.zsh
fi
source $HOME/dotfiles/antigen.zsh

source $HOME/dotfiles/.zshrc

git submodule init
git submodule update


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

