#!/bin/bash
# dotfiles の回帰テスト。
#  1. 静的チェック: 設定ファイルの内容(mise の宣言、社内名称の混入など)
#  2. 実 mise + サンドボックス HOME: dotfiles のリンク(brew / defaults には触れない)
#  3. スタブ: setup.sh の全体フロー(brew / mise / gh / cursor / code をスタブに差し替え)
# 使い方: test/setup_test.sh   (STATIC_ONLY=1 で静的チェックのみ)

set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
FAILS=0
C="$REPO/mise/config.toml"
M="$REPO/mise/config.macos.toml"
L="$REPO/mise/config.linux.toml"

pass() { echo "  ok   - $1"; }
fail() { echo "  FAIL - $1"; FAILS=$((FAILS + 1)); }
assert() { local desc="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi; }
refute() { local desc="$1"; shift; if "$@" >/dev/null 2>&1; then fail "$desc"; else pass "$desc"; fi; }

# config.macos.toml の [bootstrap.packages] に "<manager>:<name>" があるか
pkg()   { grep -qE "^\"$1\" = " "$M"; }
# 名前(tap 付きでも可)がどの manager にも無いか
nopkg() { ! grep -qE "^\"(brew|brew-cask|mas):([^\"]*/)?$1\" = " "$M"; }

echo "== static: mise 宣言 =="

for f in Brewfile Brewfile.lock.json Brewfile.macos Brewfile.linux macos.sh; do
  refute "$f is removed (migrated to mise bootstrap)" test -e "$REPO/$f"
done
for f in "$C" "$M" "$L"; do assert "$(basename "$f") exists" test -f "$f"; done

assert "mise enables experimental (bootstrap/dotfiles)" grep -qE '^experimental = true' "$C"
refute "mise config has no unknown settings.shell"      grep -qE '^shell = ' "$C"
refute "mise config has no ignored trusted_config_paths" grep -q 'trusted_config_paths' "$C"
refute "mise config does not manage aws-cli (brew awscli is used)" grep -qE '^aws-cli = ' "$C"

# パッケージ(macOS)
for p in brew:ripgrep brew:steipete/tap/summarize brew:withgraphite/tap/graphite brew:openclaw/tap/gogcli \
         brew:awscli brew:mysql@8.0 brew:ffmpeg brew:vips brew:xpdf brew:tesseract-lang \
         brew-cask:claude brew-cask:grishka/grishka/neardrop mas:302584613; do
  assert "macos packages has $p" pkg "$p"
done
for n in folly fizz wangle fbthrift fb303 mvfst boost cffi cryptography pycparser docutils \
         awslogs python@3.12 m1-terraform-provider-helper tfsec alp bluetoothconnector \
         switchaudio-osx nightlight qrencode pandoc perl entire heroku \
         sequel-ace postman licecap codexbar kindle wkhtmltopdf 540348655; do
  refute "macos packages has no $n" bash -c "grep -qE '^\"(brew|brew-cask|mas):([^\"]*/)?$n\" = ' '$M'"
done

# ツール: 全環境 / macOS のみ
for t in jq delta sheldon fzf; do
  assert "common tool $t is unrestricted" grep -qE "^$t = \"latest\"" "$C"
done
for t in node ruby go rust bun uv; do
  assert "heavy tool $t is macOS-only" grep -qE "^$t = \{.*os = \[\"macos\"\]" "$C"
done
for t in actionlint ecspresso tflint '"aqua:fujiwara/lambroll"' '"aqua:fujiwara/tfstate-lookup"' '"pipx:poetry"'; do
  assert "mise config has $t" grep -qE "^$t = " "$C"
done

# dotfiles
assert "claude settings link is relative (Dev Container safe)" grep -qE '^"~/.claude/settings.json" = .*relative = true' "$C"
assert "codex config link is relative"   grep -qE '^"~/.codex/config.toml" = .*relative = true' "$C"
assert "skills dir is linked for claude" grep -qE '^"~/.claude/skills" = ' "$C"
assert "skills dir is linked for codex"  grep -qE '^"~/.codex/skills" = ' "$C"
assert "karabiner is managed on macOS"   grep -q 'karabiner.json' "$M"
assert "cursor settings managed on macOS" grep -q 'Cursor/User/settings.json' "$M"
assert "gitconfig.os is macos on macOS"  grep -q 'gitconfig.macos' "$M"
assert "gitconfig.os is linux on Linux"  grep -q 'gitconfig.linux' "$L"
refute "linux config has no macOS packages" grep -q 'bootstrap.packages' "$L"

# macOS defaults
assert "defaults: dock autohide"  grep -qE '^autohide = true' "$M"
assert "defaults: key repeat"     grep -qE '^KeyRepeat = 2' "$M"
assert ".zshenv selects MISE_ENV" grep -q 'MISE_ENV' "$REPO/.zshenv"

echo "== static: setup.sh / 周辺 =="

assert "setup.sh runs mise bootstrap"    grep -q 'mise bootstrap' "$REPO/setup.sh"
refute "setup.sh no longer uses brew bundle" grep -q 'brew bundle' "$REPO/setup.sh"
assert "setup.sh backs up conflicting files" grep -q 'not a symlink' "$REPO/setup.sh"
assert "setup.sh apt step has tree and vim"  grep -qE 'apt-get install.*tree.*vim|apt-get install.*vim.*tree' "$REPO/setup.sh"
assert "setup.sh installs gh-stack extension" grep -q 'extension install github/gh-stack' "$REPO/setup.sh"

assert ".zshrc guards safe-chain"     grep -qE '\[\[? -f .*safe-chain.*\]\]? *(&&|;)' "$REPO/.zshrc"
assert ".bashrc guards safe-chain"    grep -qE '\[\[? -f .*safe-chain.*\]\]? *(&&|;)' "$REPO/.bashrc"
refute ".zshrc has no dead flutter PATH" grep -q 'development/flutter' "$REPO/.zshrc"
refute ".zshrc has no hub alias"           grep -q 'hub browse' "$REPO/.zshrc"
refute ".zshrc has no intel openssl PATH"  grep -q '/usr/local/opt/openssl' "$REPO/.zshrc"
refute ".bashrc has no peco"               grep -q 'peco' "$REPO/.bashrc"
refute ".bashrc has no hub"                grep -qE '(^|[^a-z])hub ' "$REPO/.bashrc"
refute ".bashrc does not shadow gh"        grep -qE "^alias gh=" "$REPO/.bashrc"
assert ".gitignore_global ignores claude settings.local.json" grep -qxF '**/.claude/settings.local.json' "$REPO/.gitignore_global"

assert "README documents the test script" grep -q 'test/setup_test.sh' "$REPO/README.md"
assert "README documents manual steps"    grep -q '手動' "$REPO/README.md"
assert "README documents mise bootstrap"  grep -q 'mise bootstrap' "$REPO/README.md"
refute "README has no stale macOS versions" grep -q 'Monterey' "$REPO/README.md"
assert "README documents company marketplace step" grep -q 'marketplace add' "$REPO/README.md"

for f in editors/vscode/settings.json editors/vscode/keybindings.json editors/cursor/settings.json editors/cursor/keybindings.json karabiner/karabiner.json; do
  assert "$f is tracked in repo" test -f "$REPO/$f"
  refute "$f has no secrets"     grep -Eiq '(secret|password|passwd|api[_-]?key|bearer|access[_-]?token)' "$REPO/$f"
  refute "$f has no internal names" grep -Eiq '(smartbank|factoring|b43|bocal)' "$REPO/$f"
done
refute "vscode rubyLsp does not use rbenv" grep -q '"identifier": "rbenv"' "$REPO/editors/vscode/settings.json"
assert "cursor extensions list exists"     test -f "$REPO/editors/cursor/extensions.txt"
assert "cursor extensions has prettier"    grep -qx 'esbenp.prettier-vscode' "$REPO/editors/cursor/extensions.txt"
refute "cursor extensions has no built-in anysphere.*" grep -q '^anysphere\.' "$REPO/editors/cursor/extensions.txt"
assert "vscode extensions list exists"     test -f "$REPO/editors/vscode/extensions.txt"
assert "vscode extensions has prettier"    grep -qx 'esbenp.prettier-vscode' "$REPO/editors/vscode/extensions.txt"

assert "CI workflow runs this test" grep -q 'test/setup_test.sh' "$REPO/.github/workflows/test.yml"
refute "tracked files have no private names" \
  git -C "$REPO" grep -qEi 'smartbank-inc/|factoring-core|bocal|core01\.b43|b43-core' -- . ':!test/setup_test.sh'
refute ".entire is not tracked"            test -n "$(git -C "$REPO" ls-files .entire)"
refute "claude settings has no .entire rule" grep -q '\.entire' "$REPO/claude/settings.json"
assert "settings declares ruby-skills marketplace" \
  python3 -c "import json,sys;d=json.load(open('$REPO/claude/settings.json'));sys.exit(0 if 'ruby-skills' in d['extraKnownMarketplaces'] else 1)"

[ "${STATIC_ONLY:-0}" = "1" ] && { echo; echo "FAILS=$FAILS"; exit $((FAILS > 0)); }

# ---------------------------------------------------------------------------
REAL_MISE="$(command -v mise || true)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/realbin"

new_home() { # new_home <name> : 空の HOME を作り、dotfiles への相対的でないリンクを置く
  export HOME="$TMP/$1"
  rm -rf "$HOME"; mkdir -p "$HOME"
  ln -s "$REPO" "$HOME/dotfiles"
}

if [ -n "$REAL_MISE" ]; then
  echo "== real mise (sandboxed HOME, dotfiles only) =="
  ln -sf "$REAL_MISE" "$TMP/realbin/mise"
  new_home real
  export MISE_STATE_DIR="$TMP/mise-state" MISE_CACHE_DIR="$TMP/mise-cache" MISE_DATA_DIR="$TMP/mise-data"
  export PATH="$TMP/realbin:/usr/bin:/bin"
  echo "legacy" > "$HOME/.zshrc"                      # 通常ファイルは .bak に退避されること
  SETUP_LINKS_ONLY=1 zsh "$REPO/setup.sh" > "$TMP/real1.log" 2>&1
  assert "links-only run exits 0" test $? -eq 0
  assert ".zshrc is symlink to repo"      test "$(readlink "$HOME/.zshrc")" = "$HOME/dotfiles/.zshrc"
  assert "legacy .zshrc backed up"        test "$(cat "$HOME/.zshrc.bak" 2>/dev/null)" = "legacy"
  assert ".gitconfig.os is linked (macOS)" test "$(readlink "$HOME/.gitconfig.os")" = "$HOME/dotfiles/.gitconfig.macos"
  assert "mise config linked"             test -L "$HOME/.config/mise/config.toml"
  assert "sheldon config linked"          test -L "$HOME/.config/sheldon/plugins.toml"
  assert "claude settings link is relative" test "$(readlink "$HOME/.claude/settings.json")" = "../dotfiles/claude/settings.json"
  assert "claude settings resolve"        test -f "$HOME/.claude/settings.json"
  assert "claude skills resolve"          test -d "$HOME/.claude/skills/review"
  assert "codex skills resolve"           test -d "$HOME/.codex/skills/review"
  assert "codex config resolves"          test -f "$HOME/.codex/config.toml"
  assert "Code settings linked"           test "$(readlink "$HOME/Library/Application Support/Code/User/settings.json")" = "$HOME/dotfiles/editors/vscode/settings.json"
  assert "Cursor keybindings linked"      test "$(readlink "$HOME/Library/Application Support/Cursor/User/keybindings.json")" = "$HOME/dotfiles/editors/cursor/keybindings.json"
  assert "karabiner.json linked"          test "$(readlink "$HOME/.config/karabiner/karabiner.json")" = "$HOME/dotfiles/karabiner/karabiner.json"
  SETUP_LINKS_ONLY=1 zsh "$REPO/setup.sh" > "$TMP/real2.log" 2>&1
  assert "second links-only run exits 0 (idempotent)" test $? -eq 0
  refute "second run creates no extra .bak" test -e "$HOME/.zshrc.bak.bak"
  unset MISE_STATE_DIR MISE_CACHE_DIR MISE_DATA_DIR
else
  echo "== real mise: SKIPPED (mise not found) =="
fi

echo "== setup.sh full flow (stubbed brew/mise/gh/cursor/code) =="
new_home stub
LOG="$TMP/calls.log"; : > "$LOG"
for cmd in brew gh cursor code; do
  printf '#!/bin/sh\necho "%s $*" >> "%s"\nexit 0\n' "$cmd" "$LOG" > "$TMP/bin/$cmd"
  chmod +x "$TMP/bin/$cmd"
done
cat > "$TMP/bin/mise" <<EOF
#!/bin/sh
echo "mise \$* env=\$MISE_ENV" >> "$LOG"
if [ "\$1" = "dotfiles" ] && [ "\$2" = "status" ]; then
  echo "~/.zshrc                  symlink  ~/dotfiles/.zshrc  ~/.config/mise/config.toml  differs (exists but is not a symlink)"
fi
exit 0
EOF
chmod +x "$TMP/bin/mise"
export PATH="$TMP/bin:/usr/bin:/bin" BREW_BIN="$TMP/bin/brew"
for cmd in brew mise gh cursor code; do
  if [ "$(command -v $cmd)" != "$TMP/bin/$cmd" ]; then echo "ABORT: real $cmd reachable"; exit 2; fi
done

echo "legacy" > "$HOME/.zshrc"
zsh "$REPO/setup.sh" > "$TMP/stub1.log" 2>&1
assert "setup.sh exits 0" test $? -eq 0
assert "conflicting regular file backed up" test "$(cat "$HOME/.zshrc.bak" 2>/dev/null)" = "legacy"
assert "mise bootstrap invoked with MISE_ENV=macos" grep -qE '^mise bootstrap .*--force-dotfiles.* env=macos$' "$LOG"
refute "brew bundle is not used"        grep -q '^brew bundle' "$LOG"
assert "gh-stack extension installed"   grep -q '^gh extension install github/gh-stack' "$LOG"
assert "cursor extensions installed"    grep -q '^cursor --install-extension esbenp.prettier-vscode' "$LOG"
assert "vscode extensions installed"    grep -q '^code --install-extension esbenp.prettier-vscode' "$LOG"
assert "mise config symlinked for bootstrap" test -L "$HOME/.config/mise/config.macos.toml"

zsh "$REPO/setup.sh" > "$TMP/stub2.log" 2>&1
assert "second run exits 0 (idempotent)" test $? -eq 0

: > "$LOG"
SETUP_LINKS_ONLY=1 zsh "$REPO/setup.sh" > "$TMP/stub3.log" 2>&1
assert "links-only run exits 0"         test $? -eq 0
assert "links-only runs only dotfiles"  grep -qE '^mise bootstrap --only dotfiles' "$LOG"
refute "links-only does not call gh/cursor/code/brew" grep -qE '^(gh|cursor|code|brew) ' "$LOG"

echo
echo "FAILS=$FAILS"
exit $((FAILS > 0))
