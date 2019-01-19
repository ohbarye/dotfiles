#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...
export LC_ALL='ja_JP.UTF-8'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
export GOPATH="$HOME/.go"
export PATH=$GOPATH/bin:$PATH 

source $HOME/dotfiles/antigen/antigen.zsh

antigen bundle sorin-ionescu/prezto

function setrepo() {
  GIT_CURRENT_BRANCH=$( git symbolic-ref --short HEAD 2> /dev/null )
  GIT_CURRENT_REPO=$( git config --get remote.origin.url | sed 's/^.*git@github.com[:/]\(.*\)/\1/' | sed 's/^\(.*\).git/\1/' )
}

# ciopen / propen command
function propen() {
  setrepo
  open "https://github.com/${GIT_CURRENT_REPO}/pull/${GIT_CURRENT_BRANCH}"
}

function ciopen() {
  setrepo
  open "https://circleci.com/gh/${GIT_CURRENT_REPO}/tree/${GIT_CURRENT_BRANCH}"
}

# rails
alias r='rails'

# bundler
alias bi='bundle install -j4'
alias be='bundle exec'
alias ber='bundle exec rspec'

# git
alias g='git'

function cd-ghq-list() {
    local DIR=$(ghq list | peco)
    if [ -n "$DIR" ]; then
        cd "$(ghq root)/$DIR"
    fi
}
alias gr=cd-ghq-list
alias gh='hub browse $(ghq list | peco | cut -d "/" -f 2,3)'

# RubyMine
alias mine='mine $(ghq root)/$(ghq list | peco)'

# docker
alias dc='docker-compose'
alias dcr='docker-compose run --rm $(basename $(pwd))'
alias de='docker exec -it qall-$(basename $(pwd))'

# key binding
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey "^[u" undo
bindkey "^[r" redo

# http://k0kubun.hatenablog.com/entry/2014/07/06/033336
alias -g B='`git branch | peco | sed -e "s/^\*[ ]*//g"`'

# http://k0kubun.hatenablog.com/entry/2014/07/06/033336
function peco-select-history() {
    BUFFER=$(fc -l -r -n 1 | peco --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle redisplay
}

# http://k0kubun.hatenablog.com/entry/2014/07/06/033336
zle -N peco-select-history
bindkey '^r' peco-select-history

function peco-find-file() {
    if git rev-parse 2> /dev/null; then
        source_files=$(git ls-files)
    else
        source_files=$(find . -type f)
    fi
    selected_files=$(echo $source_files | peco --prompt "[find file]")

    BUFFER="${BUFFER}$(echo $selected_files | tr '\n' ' ')"
    CURSOR=$#BUFFER
    zle redisplay
}
zle -N peco-find-file
bindkey '^q' peco-find-file

export PATH="/usr/local/opt/postgresql@9.5/bin:$PATH"

if [ $commands[kubectl] ]; then
  source <(kubectl completion zsh)
fi

# Kubernetes settings
alias ks='kubectl'

kss() {
  ks config get-contexts | sed "/^\ /d"
  ks auth can-i get ns >/dev/null 2>&1 && echo "(Authorized)" || echo "(Unauthorized)"
}

kc() {
  test "$1" = "-" && kubectx - || kubectx "$(kubectx | peco)"
}

kn() {
  test "$1" = "-" && kubens - || kubens "$(kubens | peco)"
}


autoload -U colors; colors
source /usr/local/etc/zsh-kubectl-prompt/kubectl.zsh
RPROMPT='%{$fg[blue]%}($ZSH_KUBECTL_PROMPT)%{$reset_color%}'

