#!/bin/bash

DOT_FILES=( .bash_profile .zshrc .gitconfig .vimrc .vim .bundle )

for file in ${DOT_FILES[@]}
do
  ln -s $HOME/dotfiles/$file $HOME/$file
done
