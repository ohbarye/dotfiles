export PATH=/usr/local/bin:$PATH

PATH=$PATH:~/play-2.2.6
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
export PATH=$HOME/.rbenv/bin:$PATH
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi 

