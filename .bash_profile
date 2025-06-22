export PATH=/usr/local/bin:$PATH

# rbenv
export PATH=$HOME/.rbenv/bin:$PATH

export EDITOR=vim

test -r ~/.bashrc && . ~/.bashrc

. "$HOME/.cargo/env"

. "$HOME/.local/bin/env"
