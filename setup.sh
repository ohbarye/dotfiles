#!/bin/zsh

set -u

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

if [ ! -e $HOME/dotfiles/antigen.zsh ]; then
  curl -L git.io/antigen > $HOME/dotfiles/antigen.zsh
fi

source $HOME/dotfiles/.zshrc

git submodule init
git submodule update


if [ ! -x "`which brew`" ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
brew update

brew bundle --file $HOME/dotfiles/Brewfile

