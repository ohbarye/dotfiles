#!/bin/zsh
# dotfiles のセットアップ。実体の宣言は mise/config*.toml にあり、`mise bootstrap` が適用する。
#   config.toml        全環境共通(ツール、dotfiles のリンク)
#   config.macos.toml  macOS(パッケージ、defaults、エディタ設定)   MISE_ENV=macos
#   config.linux.toml  Linux / Dev Container                         MISE_ENV=linux
# このスクリプトは「mise を用意して bootstrap を呼ぶ」ための薄い起点。
#
# 使い方:
#   ./setup.sh                      フルセットアップ
#   SETUP_LINKS_ONLY=1 ./setup.sh   dotfiles のリンクだけ(パッケージ導入・defaults は行わない)

set -u

case "$(uname -s)" in
    Linux)  OS_TYPE="linux";  BREW_PREFIX="/home/linuxbrew/.linuxbrew" ;;
    Darwin) OS_TYPE="macos";  BREW_PREFIX="/opt/homebrew" ;;
    *)      echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac
echo "Detected OS: $OS_TYPE"

DOTFILES_DIR="$HOME/dotfiles"

# 既存のファイルがあれば .bak に退避してからリンクする(mise が設定を読むための最小限のリンク)
link_with_backup() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    ln -sfn "$src" "$dst"
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.bak"
    ln -s "$src" "$dst"
  else
    ln -s "$src" "$dst"
  fi
}

# macOS: Homebrew を用意する。BREW_BIN は外部から上書き可能(テストでスタブを差し込むため)
ensure_brew() {
  BREW_BIN="${BREW_BIN:-}"
  if [ -z "$BREW_BIN" ]; then
    if command -v brew >/dev/null 2>&1; then
      BREW_BIN="$(command -v brew)"
    elif [ -x "$BREW_PREFIX/bin/brew" ]; then
      BREW_BIN="$BREW_PREFIX/bin/brew"
    else
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      BREW_BIN="$BREW_PREFIX/bin/brew"
    fi
  fi
  eval "$("$BREW_BIN" shellenv)"
}

ensure_mise() {
  command -v mise >/dev/null 2>&1 && return 0
  echo "Installing mise..."
  if [ "$OS_TYPE" = "macos" ]; then
    ensure_brew
    "$BREW_BIN" install mise
  else
    # Dev Container など Homebrew の無い Linux: 公式インストーラで ~/.local/bin に入れる
    curl -fsSL https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
  command -v mise >/dev/null 2>&1
}

# dotfiles の置き換え先に通常ファイルがあれば .bak に退避する。
# (mise は通常ファイルの上書きを拒否し、--force-dotfiles で上書きすると元に戻せないため)
backup_conflicting_files() {
  local target
  mise dotfiles status 2>/dev/null | awk -F'  +' '/exists but is not a symlink/ {print $1}' |
  while IFS= read -r target; do
    target="${target/#\~/$HOME}"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      mv "$target" "$target.bak" && echo "Backed up: $target -> $target.bak"
    fi
  done
}

# 1. mise の設定をリンク(bootstrap が読む)
for f in config.toml config.macos.toml config.linux.toml; do
  link_with_backup "$DOTFILES_DIR/mise/$f" "$HOME/.config/mise/$f"
done

export MISE_ENV="$OS_TYPE"
export MISE_EXPERIMENTAL=1

# 2. リンクだけ張る場合
if [ "${SETUP_LINKS_ONLY:-0}" = "1" ]; then
  ensure_mise || { echo "mise is required (SETUP_LINKS_ONLY=1)"; exit 1; }
  backup_conflicting_files
  mise bootstrap --only dotfiles --force-dotfiles --yes
  exit $?
fi

# 3. Linux(Dev Container 含む): apt で入れるもの(失敗しても続行)
if [ "$OS_TYPE" = "linux" ] && command -v apt-get >/dev/null 2>&1; then
  echo "Installing Linux packages..."
  sudo apt-get update || echo "Warning: Failed to update package list"
  sudo apt-get install -y xdg-utils libnotify-bin tree vim silversearcher-ag \
    || echo "Warning: Failed to install some packages"
fi

# 4. macOS は Homebrew、全環境で mise を用意して bootstrap を適用する
[ "$OS_TYPE" = "macos" ] && ensure_brew
ensure_mise || { echo "mise is required"; exit 1; }
backup_conflicting_files
mise bootstrap --force-dotfiles --yes || echo "Warning: mise bootstrap reported errors"

# 5. bootstrap で宣言できない後処理(失敗しても続行)
# 第三者 skill(agents/skills.manifest)を固定した ref で再現する
"$DOTFILES_DIR/scripts/install-skills.sh" || echo "Warning: some skills failed to install"

if command -v gh >/dev/null 2>&1; then
  if ! gh extension list 2>/dev/null | grep -q 'github/gh-stack'; then
    gh extension install github/gh-stack || echo "Warning: failed to install gh-stack extension (run 'gh auth login' first?)"
  fi
fi

install_editor_extensions() { # install_editor_extensions <cli> <list-file>
  local cli="$1" list="$2" ext
  command -v "$cli" >/dev/null 2>&1 && [ -f "$list" ] || return 0
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    "$cli" --install-extension "$ext" || echo "Warning: failed to install $cli extension $ext"
  done < "$list"
}
if [ "$OS_TYPE" = "macos" ]; then
  install_editor_extensions cursor "$DOTFILES_DIR/editors/cursor/extensions.txt"
  install_editor_extensions code   "$DOTFILES_DIR/editors/vscode/extensions.txt"
fi
