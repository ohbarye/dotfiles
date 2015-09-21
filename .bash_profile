export PATH=/usr/local/bin:$PATH

# play
PATH=$PATH:~/play-2.2.6

# pyenv
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

# rbenv
export PATH=$HOME/.rbenv/bin:$PATH
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi 

# bash completion
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi
