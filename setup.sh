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

# `relative = true` の dotfile リンク(Dev Container へのマウントで壊れない)は mise 2026.9.14 以降。
# 古いと相対リンクが静かに絶対パスになるため、最低バージョンを満たすように導入・更新する。
MIN_MISE_VERSION="2026.9.14"

version_ge() { # version_ge <actual> <required>
  awk -v a="$1" -v b="$2" 'BEGIN{n=split(a,x,/[.]/);split(b,y,/[.]/);for(i=1;i<=3;i++){if(x[i]+0>y[i]+0)exit 0;if(x[i]+0<y[i]+0)exit 1}exit 0}'
}

ensure_mise() {
  if command -v mise >/dev/null 2>&1; then
    local current
    current="$(mise --version 2>/dev/null | awk '{print $1}')"
    version_ge "$current" "$MIN_MISE_VERSION" && return 0
    echo "mise $current is older than $MIN_MISE_VERSION; upgrading..."
    if [ "$OS_TYPE" = "macos" ]; then
      ensure_brew
      "$BREW_BIN" update
      "$BREW_BIN" upgrade mise
    else
      mise self-update --yes || { curl -fsSL https://mise.run | sh; export PATH="$HOME/.local/bin:$PATH"; }
    fi
  else
    echo "Installing mise..."
    if [ "$OS_TYPE" = "macos" ]; then
      ensure_brew
      "$BREW_BIN" install mise
    else
      # Dev Container など Homebrew の無い Linux: 公式インストーラで ~/.local/bin に入れる
      curl -fsSL https://mise.run | sh
      export PATH="$HOME/.local/bin:$PATH"
    fi
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

# 段階ごとに独立して実行する(`mise bootstrap` は途中で失敗するとそこで止まり、残りが適用されないため)。
# 順序: dotfiles(設定を最優先で反映) → パッケージ(ツールのビルドに必要) → defaults と tools
run_stage() { # run_stage <label> <mise bootstrap args...>
  local label="$1"; shift
  echo "==> mise bootstrap: $label"
  mise bootstrap "$@" || echo "Warning: mise bootstrap stage '$label' reported errors (continuing)"
}
# macOS: mise では導入できないことが分かっているパッケージ(mise/brew-direct.txt。理由は同ファイルに記載)を、
# brew で 1 件ずつ先に入れる。1 件失敗しても残りを続行する。それ以外の cask と formula は mise に任せる。
brew_install_tolerant() { # brew_install_tolerant <formula|cask> <name>
  local kind="$1" name="$2"
  if [ "$kind" = "cask" ]; then
    "$BREW_BIN" list --cask "$name" >/dev/null 2>&1 && return 0
    echo "==> brew install --cask $name"
    "$BREW_BIN" install --cask "$name" || echo "Warning: failed to install cask $name"
  else
    "$BREW_BIN" list --formula "$name" >/dev/null 2>&1 && return 0
    echo "==> brew install $name"
    "$BREW_BIN" install "$name" || echo "Warning: failed to install formula $name"
  fi
}

preinstall_brew_direct_packages() {
  local kind name
  while read -r kind name _; do
    case "$kind" in ''|'#'*) continue ;; esac
    brew_install_tolerant "$kind" "$name"
  done < "$DOTFILES_DIR/mise/brew-direct.txt"
}

backup_conflicting_files
run_stage "dotfiles" --only dotfiles --force-dotfiles --yes
if [ "$OS_TYPE" = "macos" ]; then
  preinstall_brew_direct_packages
  run_stage "packages" --only packages --yes
fi
run_stage "defaults / tools" --skip dotfiles,packages --yes

# 5. bootstrap で宣言できない後処理(失敗しても続行)
# 第三者 skill(agents/skills.manifest)を固定した ref で再現する
"$DOTFILES_DIR/scripts/install-skills.sh" || echo "Warning: some skills failed to install"

if command -v gh >/dev/null 2>&1; then
  if ! gh extension list 2>/dev/null | grep -q 'github/gh-stack'; then
    gh extension install github/gh-stack || echo "Warning: failed to install gh-stack extension (run 'gh auth login' first?)"
  fi
fi

install_editor_extensions() { # install_editor_extensions <cli> <list-file>
  local cli="$1" list="$2" ext installed
  command -v "$cli" >/dev/null 2>&1 && [ -f "$list" ] || return 0
  # Node の非推奨警告(DEP0169)は拡張機能 CLI 由来でノイズになるため抑制する
  installed="$(NODE_NO_WARNINGS=1 "$cli" --list-extensions 2>/dev/null)"
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    # 導入済みはスキップ(拡張 ID は大文字小文字を区別しない)
    if printf '%s\n' "$installed" | grep -qixF "$ext"; then continue; fi
    NODE_NO_WARNINGS=1 "$cli" --install-extension "$ext" || echo "Warning: failed to install $cli extension $ext"
  done < "$list"
}
if [ "$OS_TYPE" = "macos" ]; then
  install_editor_extensions cursor "$DOTFILES_DIR/editors/cursor/extensions.txt"
  install_editor_extensions code   "$DOTFILES_DIR/editors/vscode/extensions.txt"
fi
