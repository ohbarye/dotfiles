# antigen, oh-my-zsh settings start
source $HOME/dotfiles/antigen.zsh

# oh-my-zsh sets HISTFILE as .zsh_history by default. This line just make it explicit.
HISTFILE="$HOME/.zsh_history"

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

antigen bundle git
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle agkozak/zsh-z

# Load the theme.
antigen theme ys

# Tell Antigen that you're done.
antigen apply
# antigen, oh-my-zsh settings end


# Linux only settings
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
		# Linuxbrew PATH (Linux only)
    export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
		# open コマンドの対応
    alias open='xdg-open'
fi

# 通知コマンドの関数化
notify() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "display notification \"$1\" with title \"$2\""
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        notify-send "$2" "$1"
    fi
}

function setrepo() {
  GIT_CURRENT_BRANCH=$( git symbolic-ref --short HEAD 2> /dev/null )
  GIT_CURRENT_REPO=$( git config --get remote.origin.url | sed 's/^.*github.com[:/]\(.*\).git/\1/' | sed 's/^.*github.com[:/]\(.*\)/\1/' )
}

# propen command
function propen() {
  setrepo
  open "https://github.com/${GIT_CURRENT_REPO}/pull/${GIT_CURRENT_BRANCH}"
}

function git-push-set-upstream() {
  setrepo
  git push --set-upstream origin ${GIT_CURRENT_BRANCH} && propen
}

alias gps=git-push-set-upstream

# rails
alias r='rails'

# bundler
alias bi='bundle install'
alias be='bundle exec'
alias ber='bundle exec rspec'
alias bepr='bundle exec parallel_rspec'

# git
alias g='git'

function cd-ghq-list() {
    local DIR=$(ghq list | fzf)
    if [ -n "$DIR" ]; then
        cd "$(ghq root)/$DIR"
    fi
}
alias gr=cd-ghq-list
alias ghb='hub browse $(ghq list | fzf | cut -d "/" -f 2,3)'

# RubyMine
alias rbl='rubymine $(ghq root)/$(ghq list | fzf)'

# Goland
alias gol='goland $(ghq root)/$(ghq list | fzf)'

# VSCode
alias cdl='code $(ghq root)/$(ghq list | fzf)'

# docker
alias d='docker'
alias dc='docker compose'
alias dcr='docker compose run --rm $(docker compose config --services | grep _api)'
alias de='docker compose exec $(docker compose ps --services | grep _api) entrypoint.sh'
function da() {
    docker attach $(docker compose ps | grep _api | awk '{print $1}')
}

# frequent commands
alias a='aws'
alias m='make'
alias :q='exit'

# For non-personal use
if [[ $(id -un) != 'ohbarye' ]]; then
  # Run docker-compose command with specific file path.
  # The path may be a kind of secret information, so it's retrieved via macOS keychain
  # ref https://qiita.com/kroyagis/items/66ca139a4c41b710a53c
  if [[ "$OSTYPE" == "darwin"* ]]; then
    export CUSTOM_DOCKER_COMPOSE_PATH=$(security find-generic-password -s "docker-compose-path" -w)
  else
    # Linux: Skip keychain access
    export CUSTOM_DOCKER_COMPOSE_PATH=""
  fi
  if [[ -f "$CUSTOM_DOCKER_COMPOSE_PATH" ]]; then
    alias bc='docker compose -f $CUSTOM_DOCKER_COMPOSE_PATH'
    alias bcr='bc run --rm $(pwd | xargs basename | sed -e "s/[a-z][0-9]\{2\}-//g")'
    alias be='bc exec $(pwd | xargs basename | sed -e "s/[a-z][0-9]\{2\}-//g") entrypoint.sh'
    function ba() {
        docker attach $(bc ps | grep _api | awk '{print $1}')
    }
  fi
fi

# key binding
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey "^[u" undo
bindkey "^[r" redo

# http://k0kubun.hatenablog.com/entry/2014/07/06/033336
alias -g B='`git br | fzf | sed -e "s/^\*[ ]*//g"`'

# http://k0kubun.hatenablog.com/entry/2014/07/06/033336
function fzf-select-history() {
    BUFFER=$(fc -l -r -n 1 | fzf --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle redisplay
}

# http://k0kubun.hatenablog.com/entry/2014/07/06/033336
zle -N fzf-select-history
bindkey '^r' fzf-select-history

function fzf-find-file() {
    if git rev-parse 2> /dev/null; then
        source_files=$(git ls-files)
    else
        source_files=$(find . -type f)
    fi
    selected_files=$(echo $source_files | fzf --prompt "[find file]")

    BUFFER="${BUFFER}$(echo $selected_files | tr '\n' ' ')"
    CURSOR=$#BUFFER
    zle redisplay
}
zle -N fzf-find-file
bindkey '^q' fzf-find-file

# AWS MFA with 1password
alias am='op item get gq4qntsm24dhtk6xrbgxr4r274 --otp | aws-mfa --duration 86400 --force'

autoload -U colors; colors

# Ruby
[[ -d ~/.rbenv  ]] && \
  export PATH=${HOME}/.rbenv/bin:${PATH} && \
  eval "$(rbenv init -)"

# Go
export GOPATH="$HOME/.go"
export PATH=$GOPATH/bin:$PATH

# Flutter
export PATH="$HOME/development/flutter/bin:$PATH"

export PATH="/usr/local/opt/openssl@3/bin:$PATH"

# For profiling https://qiita.com/vintersnow/items/7343b9bf60ea468a4180
# If it's unnecessary, comment out `zmodload zsh/zprof && zprof` in .zshenv
if (which zprof > /dev/null 2>&1) ;then
  zprof
fi

eval "$(mise activate zsh)"

# bun completions
[ -s "/Users/m-ohba/.bun/_bun" ] && source "/Users/m-ohba/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias claude-mem='/Users/m-ohba/.bun/bin/bun "/Users/m-ohba/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'
