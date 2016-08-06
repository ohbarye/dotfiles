#!/bin/bash

DOT_FILES=( .bash_profile .bashrc .zshrc .gitconfig .vimrc .vim .bundle .gitignore_global .tmux .tmux.conf )

for file in ${DOT_FILES[@]}
do
  ln -s $HOME/dotfiles/$file $HOME/$file
done
