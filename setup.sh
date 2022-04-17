#!/bin/zsh

set -u

DOT_FILES=( .bash_profile .bashrc .gitconfig .vimrc .vim .bundle .gitignore_global .zlogin .zlogout .zprofile .zshenv .zshrc .tigrc .ideavimrc )

for file in ${DOT_FILES[@]}
do
  if [ ! -e $HOME/$file ]; then
    ln -s $HOME/dotfiles/$file $HOME/$file
  fi
done

if [ ! -e $HOME/$file ]; then
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

brew bundle

