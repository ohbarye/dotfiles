#!/bin/bash
# setup.sh の回帰テスト。HOME を一時ディレクトリに差し替え、brew / mise はスタブに置き換えて実行する。
# 使い方: test/setup_test.sh   (STATIC_ONLY=1 で setup.sh を実行しない静的チェックのみ)

set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
FAILS=0

pass() { echo "  ok   - $1"; }
fail() { echo "  FAIL - $1"; FAILS=$((FAILS + 1)); }
assert() { # assert "説明" コマンド...
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi
}
refute() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then fail "$desc"; else pass "$desc"; fi
}

echo "== static checks =="

assert "Brewfile.macos has ripgrep"   grep -q '^brew "ripgrep"' "$REPO/Brewfile.macos"
assert "Brewfile.macos has summarize" grep -q 'summarize' "$REPO/Brewfile.macos"
assert "Brewfile.macos has graphite"  grep -q 'graphite' "$REPO/Brewfile.macos"
assert "Brewfile.macos has claude cask" grep -q '^cask "claude"' "$REPO/Brewfile.macos"
refute "stale Brewfile is removed"    test -e "$REPO/Brewfile"
refute "stale Brewfile.lock.json is removed" test -e "$REPO/Brewfile.lock.json"
assert ".zshrc guards safe-chain"     grep -qE '\[\[? -f .*safe-chain.*\]\]? *(&&|;)' "$REPO/.zshrc"
assert ".bashrc guards safe-chain"    grep -qE '\[\[? -f .*safe-chain.*\]\]? *(&&|;)' "$REPO/.bashrc"
refute ".zshrc has no dead flutter PATH" grep -q 'development/flutter' "$REPO/.zshrc"
assert "setup.sh runs mise install"   grep -q 'mise install' "$REPO/setup.sh"

assert ".gitignore_global ignores claude settings.local.json" grep -qxF '**/.claude/settings.local.json' "$REPO/.gitignore_global"
refute "mise config has no ignored trusted_config_paths" grep -q 'trusted_config_paths' "$REPO/mise/config.toml"
assert "README documents the test script" grep -q 'test/setup_test.sh' "$REPO/README.md"
assert "README documents manual steps"    grep -q '手動' "$REPO/README.md"
refute "README has no stale macOS versions" grep -q 'Monterey' "$REPO/README.md"

assert "macos.sh exists and is executable" test -x "$REPO/macos.sh"
assert "macos.sh sets dock autohide"      grep -q 'com.apple.dock autohide -bool true' "$REPO/macos.sh"
assert "macos.sh sets key repeat"         grep -q 'NSGlobalDomain KeyRepeat -int 2' "$REPO/macos.sh"
for f in editors/vscode/settings.json editors/vscode/keybindings.json editors/cursor/settings.json editors/cursor/keybindings.json karabiner/karabiner.json; do
  assert "$f is tracked in repo" test -f "$REPO/$f"
  refute "$f has no secrets"     grep -Eiq '(secret|password|passwd|api[_-]?key|bearer|access[_-]?token)' "$REPO/$f"
  refute "$f has no internal names" grep -Eiq '(smartbank|factoring|b43|bocal)' "$REPO/$f"
done

# --- Brewfile: 手動導入されていたものの追加 ---
for f in mysql@8.0 ffmpeg vips xpdf tesseract-lang; do
  assert "Brewfile.macos has $f" grep -q "^brew \"$f\"" "$REPO/Brewfile.macos"
done

# --- mise: 導入済みツールの取りこぼし ---
for t in actionlint ecspresso tflint jq '"aqua:fujiwara/lambroll"' '"aqua:fujiwara/tfstate-lookup"' '"pipx:poetry"'; do
  assert "mise config has $t" grep -qE "^$t = " "$REPO/mise/config.toml"
done

# --- エディタ ---
refute "vscode rubyLsp does not use rbenv" grep -q '"identifier": "rbenv"' "$REPO/editors/vscode/settings.json"
assert "cursor extensions list exists"     test -f "$REPO/editors/cursor/extensions.txt"
assert "cursor extensions has prettier"    grep -qx 'esbenp.prettier-vscode' "$REPO/editors/cursor/extensions.txt"
refute "cursor extensions has no built-in anysphere.*" grep -q '^anysphere\.' "$REPO/editors/cursor/extensions.txt"

# --- 不要コードの除去 ---
refute ".zshrc has no hub alias"           grep -q 'hub browse' "$REPO/.zshrc"
refute ".zshrc has no intel openssl PATH"  grep -q '/usr/local/opt/openssl' "$REPO/.zshrc"
refute ".bashrc has no peco"               grep -q 'peco' "$REPO/.bashrc"
refute ".bashrc has no hub"                grep -qE '(^|[^a-z])hub ' "$REPO/.bashrc"
refute ".bashrc does not shadow gh"        grep -qE "^alias gh=" "$REPO/.bashrc"

# --- CI ---
assert "CI workflow runs this test"        grep -q 'test/setup_test.sh' "$REPO/.github/workflows/test.yml"

# --- 公開リポジトリに社内名称が入っていないこと(コミット時フックではなくテスト/CIで検出) ---
refute "tracked files have no private names" \
  git -C "$REPO" grep -qEi 'smartbank-inc/|factoring-core|bocal|core01\.b43|b43-core' -- . ':!test/setup_test.sh'

[ "${STATIC_ONLY:-0}" = "1" ] && { echo; echo "FAILS=$FAILS"; exit $((FAILS > 0)); }

echo "== setup.sh run (sandboxed HOME, stubbed brew/mise) =="

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
mkdir -p "$HOME" "$TMP/bin"
ln -s "$REPO" "$HOME/dotfiles"
LOG="$TMP/calls.log"; : > "$LOG"

for cmd in brew mise defaults killall cursor; do
  cat > "$TMP/bin/$cmd" <<EOF
#!/bin/sh
echo "$cmd \$*" >> "$LOG"
exit 0
EOF
  chmod +x "$TMP/bin/$cmd"
done
# 実体の brew / mise に到達できないよう PATH を最小構成にし、BREW_BIN でもスタブを明示する
export PATH="$TMP/bin:/usr/bin:/bin"
export BREW_BIN="$TMP/bin/brew"
for cmd in brew mise defaults killall cursor; do
  if [ "$(command -v $cmd)" != "$TMP/bin/$cmd" ]; then echo "ABORT: real $cmd reachable"; exit 2; fi
done

# 既存の通常ファイルはバックアップされること
echo "legacy" > "$HOME/.zshrc"

zsh "$REPO/setup.sh" > "$TMP/run1.log" 2>&1
assert "setup.sh exits 0" test $? -eq 0

assert ".zshrc is symlink to repo"      test "$(readlink "$HOME/.zshrc")" = "$HOME/dotfiles/.zshrc"
assert "legacy .zshrc backed up"        test -f "$HOME/.zshrc.bak"
assert ".gitconfig.os is linked"        test -L "$HOME/.gitconfig.os"
assert "mise config linked"             test -L "$HOME/.config/mise/config.toml"
assert "sheldon config linked"          test -L "$HOME/.config/sheldon/plugins.toml"
assert "claude settings resolve"        test -f "$HOME/.claude/settings.json"
assert "claude skills resolve"          test -d "$HOME/.claude/skills/review"
assert "codex config resolves"          test -f "$HOME/.codex/config.toml"
assert "brew bundle uses Brewfile.macos" grep -q "^brew bundle --file $HOME/dotfiles/Brewfile.macos" "$LOG"
assert "mise install was invoked"       grep -q '^mise install' "$LOG"

assert "macos defaults applied (dock autohide)" grep -q '^defaults write com.apple.dock autohide -bool true' "$LOG"
assert "Code settings linked"           test "$(readlink "$HOME/Library/Application Support/Code/User/settings.json")" = "$HOME/dotfiles/editors/vscode/settings.json"
assert "Code keybindings linked"        test "$(readlink "$HOME/Library/Application Support/Code/User/keybindings.json")" = "$HOME/dotfiles/editors/vscode/keybindings.json"
assert "Cursor settings linked"         test "$(readlink "$HOME/Library/Application Support/Cursor/User/settings.json")" = "$HOME/dotfiles/editors/cursor/settings.json"
assert "Cursor keybindings linked"      test "$(readlink "$HOME/Library/Application Support/Cursor/User/keybindings.json")" = "$HOME/dotfiles/editors/cursor/keybindings.json"
assert "karabiner.json linked"          test "$(readlink "$HOME/.config/karabiner/karabiner.json")" = "$HOME/dotfiles/karabiner/karabiner.json"

assert "cursor extensions installed"    grep -q '^cursor --install-extension esbenp.prettier-vscode' "$LOG"

# 冪等性
zsh "$REPO/setup.sh" > "$TMP/run2.log" 2>&1
assert "second run exits 0 (idempotent)" test $? -eq 0
refute "second run creates no extra .bak" test -e "$HOME/.zshrc.bak.bak"

# SETUP_LINKS_ONLY=1 ではリンクだけ張り、brew / mise / defaults は呼ばない
: > "$LOG"
SETUP_LINKS_ONLY=1 zsh "$REPO/setup.sh" > "$TMP/run3.log" 2>&1
assert "links-only run exits 0"         test $? -eq 0
assert "links-only run calls nothing"   test ! -s "$LOG"

echo
echo "FAILS=$FAILS"
exit $((FAILS > 0))
