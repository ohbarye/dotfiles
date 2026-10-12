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

[ "${STATIC_ONLY:-0}" = "1" ] && { echo; echo "FAILS=$FAILS"; exit $((FAILS > 0)); }

echo "== setup.sh run (sandboxed HOME, stubbed brew/mise) =="

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
mkdir -p "$HOME" "$TMP/bin"
ln -s "$REPO" "$HOME/dotfiles"
LOG="$TMP/calls.log"; : > "$LOG"

for cmd in brew mise; do
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
if command -v brew | grep -qv "^$TMP/bin/"; then echo "ABORT: real brew reachable"; exit 2; fi

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

# 冪等性
zsh "$REPO/setup.sh" > "$TMP/run2.log" 2>&1
assert "second run exits 0 (idempotent)" test $? -eq 0
refute "second run creates no extra .bak" test -e "$HOME/.zshrc.bak.bak"

echo
echo "FAILS=$FAILS"
exit $((FAILS > 0))
