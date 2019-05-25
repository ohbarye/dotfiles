#!/bin/zsh

set -u

DOT_FILES=( .bash_profile .bashrc .zshrc .gitconfig .vimrc .vim .bundle .gitignore_global .zlogin .zlogout .zprofile .zshenv .zshrc .tigrc .ideavimrc )

for file in ${DOT_FILES[@]}
do
  if [ ! -e $HOME/$file ]; then
    ln -s $HOME/dotfiles/$file $HOME/$file
  fi
done

source $HOME/dotfiles/.zshrc

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

git submodule init
git submodule update

