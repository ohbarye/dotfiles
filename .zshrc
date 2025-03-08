export LC_ALL='ja_JP.UTF-8'
export GOPATH="$HOME/.go"
export PATH=$GOPATH/bin:$PATH

# antigen, oh-my-zsh settings start
source $HOME/dotfiles/antigen.zsh

# oh-my-zsh sets HISTFILE as .zsh_history without this line
# https://github.com/robbyrussell/oh-my-zsh/blob/1f078898887bf96e793772a80e0dae1e96eeadc8/lib/history.zsh#L29
HISTFILE="$HOME/.zhistory"

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

antigen bundle git
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-history-substring-search
antigen bundle agkozak/zsh-z

# Load the theme.
antigen theme ys

# Tell Antigen that you're done.
antigen apply
# antigen, oh-my-zsh settings start

function setrepo() {
  GIT_CURRENT_BRANCH=$( git symbolic-ref --short HEAD 2> /dev/null )
  GIT_CURRENT_REPO=$( git config --get remote.origin.url | sed 's/^.*github.com[:/]\(.*\).git/\1/' | sed 's/^.*github.com[:/]\(.*\)/\1/' )
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

function git-push-set-upstream() {
  setrepo
  git push --set-upstream origin ${GIT_CURRENT_BRANCH} && propen
}

alias gps=git-push-set-upstream

function notify-github-actions-ci-finish() {
  gh run watch -i10 && osascript -e 'display notification "run is done!" with title "Terminal"'
}

alias nci=notify-github-actions-ci-finish

# rails
alias r='rails'

# bundler
alias bi='bundle install -j4'
alias be='bundle exec'
alias ber='bundle exec rspec'

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
alias y='yarn'
alias :q='exit'

# For non-personal use
if [[ $(id -un) != 'ohbarye' ]]; then
  # Run docker-compose command with specific file path.
  # The path may be a kind of secret information, so it's retrieved via macOS keychain
  # ref https://qiita.com/kroyagis/items/66ca139a4c41b710a53c
  export CUSTOM_DOCKER_COMPOSE_PATH=$(security find-generic-password -s "docker-compose-path" -w)
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

# Kubernetes settings start
# Temporary off since I don't use kubernetes recently.
# alias ks='kubectl'
#
# kss() {
#   ks config get-contexts | sed "/^\ /d"
#   ks auth can-i get ns >/dev/null 2>&1 && echo "(Authorized)" || echo "(Unauthorized)"
# }
#
# kc() {
#   test "$1" = "-" && kubectx - || kubectx "$(kubectx | fzf)"
# }
#
# kn() {
#   test "$1" = "-" && kubens - || kubens "$(kubens | fzf)"
# }
#
# if [ $commands[kubectl] ]; then
#   source <(kubectl completion zsh)
# fi
#
# if [ -f "/usr/local/etc/zsh-kubectl-prompt/kubectl.zsh" ]; then
#   source /usr/local/etc/zsh-kubectl-prompt/kubectl.zsh
#   RPROMPT='%{$fg[blue]%}($ZSH_KUBECTL_PROMPT)%{$reset_color%}'
# fi

# Kubernetes settings end

autoload -U colors; colors

[[ -d ~/.rbenv  ]] && \
  export PATH=${HOME}/.rbenv/bin:${PATH} && \
  eval "$(rbenv init -)"

# opam configuration
test -r ${HOME}/.opam/opam-init/init.zsh && . ${HOME}/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

# deno configuration
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"
fpath=(~/.zsh $fpath)
autoload -Uz compinit
compinit -u

# For profiling https://qiita.com/vintersnow/items/7343b9bf60ea468a4180
# If it's unnecessary, comment out `zmodload zsh/zprof && zprof` in .zshenv
if (which zprof > /dev/null 2>&1) ;then
  zprof
fi


test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true

# Haskell
[ -f "${HOME}/.ghcup/env" ] && source "${HOME}/.ghcup/env" # ghcup-env

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export PATH="/usr/local/opt/openssl@3/bin:$PATH"

eval "$(mise activate zsh)"
