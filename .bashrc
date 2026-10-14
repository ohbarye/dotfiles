setrepo() {
  GIT_CURRENT_BRANCH=$( git symbolic-ref --short HEAD 2> /dev/null )
  GIT_CURRENT_REPO=$( git config --get remote.origin.url |  sed 's/^[^:]*://; s/\.git$//' )
}

# propen command
propen() {
  setrepo
  open "https://github.com/${GIT_CURRENT_REPO}/pull/${GIT_CURRENT_BRANCH}"
}

# rails
alias r='rails'

# bundler
alias bi='bundle install'
alias be='bundle exec'
alias ber='bundle exec rspec'

# git
alias g='git'
alias gr='cd $(ghq root)/$(ghq list | fzf)'
alias ghb='gh browse -R $(ghq list | fzf | cut -d "/" -f 2,3)'

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

[ -f ~/.safe-chain/scripts/init-posix.sh ] && source ~/.safe-chain/scripts/init-posix.sh # Safe-chain bash initialization script
