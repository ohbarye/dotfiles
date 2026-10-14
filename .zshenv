#
# Defines environment variables.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# For profiling https://qiita.com/vintersnow/items/7343b9bf60ea468a4180
# zmodload zsh/zprof && zprof

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# mise: OS ごとの設定(mise/config.macos.toml / config.linux.toml)を重ねる
case "$OSTYPE" in
  darwin*) export MISE_ENV=macos ;;
  linux*)  export MISE_ENV=linux ;;
esac
