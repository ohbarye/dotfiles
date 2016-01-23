export PATH=/usr/local/bin:$PATH

# rbenv
export PATH=$HOME/.rbenv/bin:$PATH

# ciopen / propen command
export GIT_CURRENT_BRANCH=$( git symbolic-ref --short HEAD 2> /dev/null )
export GIT_CURRENT_REPO=$( git config --get remote.origin.url | awk -F: '{print $2}'| sed 's/\.git$//g' )

test -r ~/.bashrc && . ~/.bashrc

