# play
PATH=$PATH:~/play-2.2.6

# pyenv
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

# rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi 

# bash completion
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

setrepo() {
  GIT_CURRENT_BRANCH=$( git symbolic-ref --short HEAD 2> /dev/null )
  GIT_CURRENT_REPO=$( git config --get remote.origin.url |  sed 's/^[^:]*://; s/\.git$//' )
}

# ciopen / propen command
propen() {
  setrepo
  open "https://github.com/${GIT_CURRENT_REPO}/pull/${GIT_CURRENT_BRANCH}"
}

ciopen() {
  setrepo
  open "https://circleci.com/gh/${GIT_CURRENT_REPO}/tree/${GIT_CURRENT_BRANCH}"
}

# aliases
alias bi='bundle install'
alias be='bundle exec'
alias ber='bundle exec rspec'

