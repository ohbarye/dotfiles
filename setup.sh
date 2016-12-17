#!/bin/zsh

DOT_FILES=( .bash_profile .bashrc .zshrc .gitconfig .vimrc .vim .bundle .gitignore_global .tmux .tmux.conf .zlogin .zlogout .zpreztorc .zprofile .zshenv .zshrc )

for file in ${DOT_FILES[@]}
do
  ln -s $HOME/dotfiles/$file $HOME/$file
done

source $HOME/dotfiles/antigen/antigen.zsh

#antigen bundle sorin-ionescu/prezto

ln -s ~/.antigen/repos/.zprezto ~/.zprezto

