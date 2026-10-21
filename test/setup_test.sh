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
for p in brew:ripgrep brew:awscli brew:mysql@8.0 brew:ffmpeg brew:vips brew:xpdf brew:tesseract-lang \
         brew-cask:claude mas:302584613; do
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
assert "setup.sh requires mise >= 2026.9.14 (relative dotfile symlinks)" grep -q '2026.9.14' "$REPO/setup.sh"
assert "CI updates Homebrew before installing mise" grep -qE 'brew update' "$REPO/.github/workflows/test.yml"

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
assert "README documents manual steps"    grep -q 'Manual steps' "$REPO/README.md"
refute "README is written in English (no CJK characters)" \
  python3 -c "import re,sys;sys.exit(0 if re.search(r'[\u3040-\u30ff\u3400-\u9fff]', open('$REPO/README.md',encoding='utf-8').read()) else 1)"
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

echo "== static: skill のマニフェスト(自作は ohbarye/agent-skills、第三者は上流) =="
MF="$REPO/agents/skills.manifest"
assert "skills manifest exists"           test -f "$MF"
assert "skills installer is executable"   test -x "$REPO/scripts/install-skills.sh"
assert "setup.sh installs manifest skills" grep -q 'install-skills.sh' "$REPO/setup.sh"
for n in cosense-memo magi-decision-support pr-lead-time review spotify-playlist-creator; do
  assert "own skill $n comes from ohbarye/agent-skills" grep -qE "^$n[[:space:]]+ohbarye/agent-skills[[:space:]]+skills/$n[[:space:]]+v[0-9]" "$MF"
done
assert "agent-browser comes from upstream" grep -qE '^agent-browser[[:space:]]+vercel-labs/agent-browser[[:space:]]+skills/agent-browser[[:space:]]' "$MF"
assert "gog comes from upstream"           grep -qE '^gog[[:space:]]+steipete/gogcli[[:space:]]+\.agents/skills/gog[[:space:]]' "$MF"
assert "summarize comes from upstream"     grep -qE '^summarize[[:space:]]+steipete/summarize[[:space:]]+\.agents/skills/summarize[[:space:]]' "$MF"
for n in archify find-skills gh-stack grill-me grilling; do
  assert "third-party skill $n is in the manifest" grep -qE "^$n[[:space:]]" "$MF"
done
assert "all skills are gitignored except .gitkeep" bash -c "grep -qxF 'agents/skills/*' '$REPO/.gitignore' && grep -qxF '!agents/skills/.gitkeep' '$REPO/.gitignore'"
assert "agents/skills/.gitkeep is tracked (link source must exist)" test -n "$(git -C "$REPO" ls-files agents/skills/.gitkeep)"
refute "no skill files are tracked under agents/skills" \
  bash -c "git -C '$REPO' ls-files agents/skills | grep -v '^agents/skills/.gitkeep$' | grep -q ."
refute "manifest refs are pinned (no main/master/HEAD/latest)" \
  bash -c "grep -vE '^[[:space:]]*(#|$)' '$MF' | awk '{print \$4}' | grep -qxE 'main|master|HEAD|latest'"

echo "== static: 不要な設定の除去 =="
for f in .vim/colors/jellybeans.vim .vim/colors/solarized.vim .zlogin .zlogout .bundle/config \
         claude/agents/web-searcher.md claude/commands/gemini-search.md codex/PLANS.md; do
  refute "$f is removed" test -e "$REPO/$f"
done
for k in '\.zlogin' '\.zlogout' '\.bundle"' 'PLANS\.md'; do
  refute "mise config has no link for $k" grep -qE "$k" "$C"
done
refute ".bash_profile has no rbenv PATH"      grep -q 'rbenv' "$REPO/.bash_profile"
refute ".bashrc has no ciopen"                grep -q 'ciopen' "$REPO/.bashrc"
for k in 'alias rbl=' 'alias gol=' 'alias cdl=' 'alias bepr=' 'zsh/zprof' 'which zprof'; do
  refute ".zshrc has no $k"                   grep -q "$k" "$REPO/.zshrc"
done
refute ".zshenv has no zprof comment"         grep -q 'zsh/zprof' "$REPO/.zshenv"
refute "codex AGENTS.md does not reference PLANS.md" grep -q 'PLANS' "$REPO/codex/AGENTS.md"
assert "codex AGENTS.md keeps ExecPlan guidance"    grep -q 'ExecPlan' "$REPO/codex/AGENTS.md"

echo "== static: 新しい Mac で bootstrap が止まらないこと =="
refute "terraform is not a brew package (removed from Homebrew core)" pkg brew:terraform
assert "terraform is a macOS-only mise tool"    grep -qE '^terraform = \{.*os = \["macos"\]' "$C"
refute "no tap-based entries in [bootstrap.packages] (need Ruby 3+ to evaluate)" \
  grep -qE '^"(brew|brew-cask):[^"/]+/[^"/]+/[^"]+" = ' "$M"
assert "setup.sh runs dotfiles as its own stage"  grep -qE 'run_stage "dotfiles" --only dotfiles' "$REPO/setup.sh"
assert "setup.sh runs packages as its own stage"  grep -qE 'run_stage "packages" --only packages' "$REPO/setup.sh"
assert "setup.sh runs the remaining stages"       grep -qE 'run_stage .* --skip dotfiles,packages' "$REPO/setup.sh"
# 宣言した brew / cask が Homebrew のコア(名前の一覧)に存在すること(キャッシュがある環境のみ)
IDX="$(brew --cache 2>/dev/null)/api"
if [ -f "$IDX/formula_names.txt" ] && [ -f "$IDX/cask_names.txt" ]; then
  assert "declared brew/cask packages exist in Homebrew core" python3 - "$IDX" "$M" <<'PYEOF'
import re,sys,os
idx,cfg=sys.argv[1:3]
def names(fn): return {l.strip().split('/')[-1] for l in open(os.path.join(idx,fn))}
f=names('formula_names.txt')|names('formula_aliases.txt') if os.path.exists(os.path.join(idx,'formula_aliases.txt')) else names('formula_names.txt')
c=names('cask_names.txt')
bad=[]
for m in re.finditer(r'^"(brew|brew-cask):([^"/]+)" = ',open(cfg).read(),re.M):
    k,n=m.groups()
    if n not in (f if k=='brew' else c): bad.append(n)
sys.exit(1 if bad else 0)
PYEOF
else
  echo "  skip - Homebrew name index not cached"
fi

# docker-desktop cask と補完ファイルが衝突する(cask が補完を提供する)
refute "docker-completion formula is not declared (conflicts with docker-desktop cask)" pkg brew:docker-completion
assert "docker-desktop cask is declared"        pkg brew-cask:docker-desktop

echo "== static: 新しい Mac での初回実行で見つかった問題 =="
for e in codesandbox-io.codesandbox-projects github.codespaces github.remotehub ics.japanese-proofreading \
         jakebecker.elixir-ls mame.ruby-typeprof ms-vscode.azure-repos ms-vscode.remote-repositories soutaro.steep-vscode; do
  refute "cursor extensions list has no $e (not available in Cursor)" grep -qxF "$e" "$REPO/editors/cursor/extensions.txt"
done
assert "setup.sh silences Node deprecation warnings of the editor CLIs" grep -q 'NODE_NO_WARNINGS' "$REPO/setup.sh"
assert "setup.sh skips already installed editor extensions" grep -q -- '--list-extensions' "$REPO/setup.sh"
assert "macOS config restarts Dock/Finder after defaults (post-defaults hook)" grep -qE '^post-defaults = .*killall' "$M"
assert "README mentions accepting the Xcode license" grep -q 'xcodebuild -license' "$REPO/README.md"

echo "== static: 2 回目の実行で見つかった問題 =="
refute "ngrok cask is not in packages (mise fails on its \$HOMEBREW_PREFIX completion path)" pkg brew-cask:ngrok
for id in 409183694 409201541 409203825; do
  refute "iWork mas id $id is not declared (apps were renamed to Creator Studio)" bash -c "grep -qE '^\"mas:$id\" = ' '$M'"
done

echo "== static: cask / tap パッケージは brew で直接入れる(mise の cask 処理が不安定なため) =="
BD="$REPO/mise/brew-direct.txt"
assert "brew-direct list exists"                 test -f "$BD"
for n in steipete/tap/summarize openclaw/tap/gogcli withgraphite/tap/graphite; do
  assert "brew-direct lists formula $n" grep -qxF "formula $n" "$BD"
done
for n in grishka/grishka/neardrop ngrok; do
  assert "brew-direct lists cask $n"    grep -qxF "cask $n" "$BD"
done
refute "no post-packages hook (installs happen in setup.sh, independent of the packages stage)" grep -q '^post-packages' "$M"
assert "setup.sh pre-installs casks with brew before mise" grep -q 'install --cask' "$REPO/setup.sh"

echo "== static: brew で直接入れるのは、原因が分かっているものだけ =="
assert "brew-direct lists the raycast cask (TLS 1.3-only redirect host vs mise's Secure Transport)" grep -qxF 'cask raycast' "$BD"
refute "raycast is not declared in mise packages (installed via brew-direct)" pkg brew-cask:raycast
refute "setup.sh does not pre-install every declared cask (only brew-direct)" grep -q 'brew-cask:' "$REPO/setup.sh"
for n in raycast ngrok; do
  assert "brew-direct documents why $n is handled by brew" grep -qi "$n" "$BD"
done

assert "brew-direct lists the warp cask (download endpoint only answers Homebrew's User-Agent)" grep -qxF 'cask warp' "$BD"
refute "warp is not declared in mise packages (installed via brew-direct)" pkg brew-cask:warp
refute "vscode extension list has no github.copilot (built-in Copilot Chat conflicts)" grep -qxF 'github.copilot' "$REPO/editors/vscode/extensions.txt"
assert "brew calls are isolated from the loop's stdin" grep -qE 'install --cask "\$name" </dev/null' "$REPO/setup.sh"

echo "== static: sudo の認証は最初に済ませる(mise の進捗表示に Password: が隠れてハングして見えるため) =="
assert "setup.sh acquires sudo up front"        grep -q 'sudo -v' "$REPO/setup.sh"
assert "setup.sh keeps the sudo timestamp alive" grep -q 'sudo -n true' "$REPO/setup.sh"

echo "== static: キーチェーンに項目が無くてもシェルの起動時にエラーを出さない =="
assert ".zshrc silences the keychain lookup (security ... 2>/dev/null)" \
  grep -qE 'security find-generic-password -s "docker-compose-path" -w 2>/dev/null' "$REPO/.zshrc"
# 実際に zsh で、項目が無い環境を再現して stderr が空であること(security をエラーを出すスタブに差し替える)
assert ".zshrc prints nothing to stderr when the keychain item is missing" bash -c "
  T=\$(mktemp -d); mkdir -p \$T/bin
  printf '#!/bin/sh\necho \"security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain.\" >&2\nexit 44\n' > \$T/bin/security; chmod +x \$T/bin/security
  sed -n '/^# For non-personal use/,/^fi\$/p' '$REPO/.zshrc' > \$T/block.zsh
  err=\$(PATH=\$T/bin:/usr/bin:/bin zsh -c 'OSTYPE=darwin23; id() { echo someone-else; }; source '\$T'/block.zsh' 2>&1 >/dev/null)
  rm -rf \$T; [ -z \"\$err\" ]"

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

echo "== skills installer (local git repos, no network) =="
GB="$TMP/gitbase"; mkdir -p "$GB/acme/skills/skills/foo"
git -C "$GB/acme/skills" init -q
echo "v1" > "$GB/acme/skills/skills/foo/SKILL.md"; echo "x" > "$GB/acme/skills/skills/foo/extra.txt"
git -C "$GB/acme/skills" add -A
git -C "$GB/acme/skills" -c user.email=t@t -c user.name=t commit -qm v1
git -C "$GB/acme/skills" tag v1.0.0
V1_SHA="$(git -C "$GB/acme/skills" rev-parse HEAD)"
echo "v2" > "$GB/acme/skills/skills/foo/SKILL.md"
git -C "$GB/acme/skills" -c user.email=t@t -c user.name=t commit -qam v2
git -C "$GB/acme/skills" tag v2.0.0
SK_DEST="$TMP/skills-dest"; SK_MF="$TMP/skills.manifest"
run_installer() { SKILLS_MANIFEST="$SK_MF" SKILLS_DEST="$SK_DEST" SKILLS_GIT_BASE="file://$GB" "$REPO/scripts/install-skills.sh"; }

printf 'foo acme/skills skills/foo v1.0.0\nbar acme/skills skills/missing v1.0.0\n' > "$SK_MF"
run_installer > "$TMP/inst0.log" 2>&1
assert "installer exits non-zero when one entry fails" test $? -ne 0
assert "other entries are still installed"   test "$(cat "$SK_DEST/foo/SKILL.md" 2>/dev/null)" = "v1"

printf '# comment\n\nfoo acme/skills skills/foo v1.0.0\n' > "$SK_MF"
run_installer > "$TMP/inst1.log" 2>&1
assert "installer exits 0"                   test $? -eq 0
assert "installs the pinned tag (v1, not latest)" test "$(cat "$SK_DEST/foo/SKILL.md")" = "v1"
assert "installs sibling files"              test -f "$SK_DEST/foo/extra.txt"
run_installer > "$TMP/inst2.log" 2>&1
assert "second run exits 0 (idempotent)"     test $? -eq 0
printf 'foo acme/skills skills/foo v2.0.0\n' > "$SK_MF"
run_installer > "$TMP/inst3.log" 2>&1
assert "bumping the ref updates the skill"   test "$(cat "$SK_DEST/foo/SKILL.md")" = "v2"
printf 'foo acme/skills skills/foo %s\n' "$V1_SHA" > "$SK_MF"
run_installer > "$TMP/inst4.log" 2>&1
assert "a commit SHA ref works"              test "$(cat "$SK_DEST/foo/SKILL.md")" = "v1"

if [ -n "$REAL_MISE" ]; then
  echo "== real mise (sandboxed HOME, dotfiles only) =="
  ln -sf "$REAL_MISE" "$TMP/realbin/mise"
  MISE_VER="$("$REAL_MISE" --version 2>/dev/null | awk '{print $1}')"
  assert "real mise supports relative dotfile symlinks (>= 2026.9.14), got $MISE_VER" \
    awk -v a="$MISE_VER" 'BEGIN{n=split(a,x,/[.]/);split("2026.9.14",y,/[.]/);for(i=1;i<=3;i++){if(x[i]+0>y[i]+0)exit 0;if(x[i]+0<y[i]+0)exit 1}exit 0}'
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
  assert "claude skills dir resolves"     test -e "$HOME/.claude/skills/.gitkeep"
  assert "codex skills dir resolves"      test -e "$HOME/.codex/skills/.gitkeep"
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
for cmd in brew gh cursor code sudo; do
  # brew は list を「未導入」とし、install では標準入力を読み切る(実際の brew が while read ループの入力を食べた挙動の再現)
  printf '#!/bin/sh\necho "%s $*" >> "%s"\n[ "%s" = brew ] && [ "$1" = list ] && exit 1\n[ "%s" = brew ] && [ "$1" = install ] && cat >/dev/null\nexit 0\n' "$cmd" "$LOG" "$cmd" "$cmd" > "$TMP/bin/$cmd"
  chmod +x "$TMP/bin/$cmd"
done
cat > "$TMP/bin/mise" <<EOF
#!/bin/sh
echo "mise \$* env=\$MISE_ENV" >> "$LOG"
if [ "\$1" = "--version" ]; then echo "\${STUB_MISE_VERSION:-2026.10.8} macos-arm64 (stub)"; exit 0; fi
if [ "\$1" = "dotfiles" ] && [ "\$2" = "status" ]; then
  echo "~/.zshrc                  symlink  ~/dotfiles/.zshrc  ~/.config/mise/config.toml  differs (exists but is not a symlink)"
fi
exit 0
EOF
chmod +x "$TMP/bin/mise"
export PATH="$TMP/bin:/usr/bin:/bin" BREW_BIN="$TMP/bin/brew"
for cmd in brew mise gh cursor code sudo; do
  if [ "$(command -v $cmd)" != "$TMP/bin/$cmd" ]; then echo "ABORT: real $cmd reachable"; exit 2; fi
done

printf 'foo acme/skills skills/foo v1.0.0\n' > "$SK_MF"; rm -rf "$SK_DEST"
export SKILLS_MANIFEST="$SK_MF" SKILLS_DEST="$SK_DEST" SKILLS_GIT_BASE="file://$GB"
echo "legacy" > "$HOME/.zshrc"
zsh "$REPO/setup.sh" > "$TMP/stub1.log" 2>&1
assert "setup.sh exits 0" test $? -eq 0
assert "conflicting regular file backed up" test "$(cat "$HOME/.zshrc.bak" 2>/dev/null)" = "legacy"
assert "dotfiles stage runs first with --force-dotfiles (MISE_ENV=macos)" grep -qE '^mise bootstrap --only dotfiles .*--force-dotfiles.* env=macos$' "$LOG"
assert "packages stage runs"            grep -qE '^mise bootstrap --only packages' "$LOG"
for n in steipete/tap/summarize openclaw/tap/gogcli withgraphite/tap/graphite; do
  assert "brew-direct formula $n is installed (even if brew reads stdin)" grep -qxF "brew install $n" "$LOG"
done
for n in grishka/grishka/neardrop ngrok raycast warp; do
  assert "brew-direct cask $n is installed (even if brew reads stdin)" grep -qxF "brew install --cask $n" "$LOG"
done
refute "ordinary declared casks are left to mise (slack)" grep -qE '^brew install --cask slack$' "$LOG"
assert "tap formula is installed by brew (summarize)"    grep -qE '^brew install steipete/tap/summarize$' "$LOG"
assert "brew-direct cask is installed (ngrok)"           grep -qE '^brew install --cask ngrok$' "$LOG"
assert "sudo is authenticated (sudo -v) once, before packages" bash -c "v=\$(grep -nE '^sudo -v\$' '$LOG' | head -1 | cut -d: -f1); m=\$(grep -nE '^mise bootstrap --only packages' '$LOG' | head -1 | cut -d: -f1); [ -n \"\$v\" ] && [ \"\$v\" -lt \"\$m\" ]"
assert "brew installs run before the mise packages stage" bash -c "b=\$(grep -nE '^brew install --cask raycast\$' '$LOG' | head -1 | cut -d: -f1); m=\$(grep -nE '^mise bootstrap --only packages' '$LOG' | head -1 | cut -d: -f1); [ -n \"\$b\" ] && [ \"\$b\" -lt \"\$m\" ]"
assert "remaining stages (defaults, tools) run" grep -qE '^mise bootstrap --skip dotfiles,packages' "$LOG"
assert "stages run in order: dotfiles < packages < rest" bash -c "n=\$(grep -nE '^mise bootstrap' '$LOG' | cut -d: -f1 | tr '\n' ' '); set -- \$n; [ \$1 -lt \$2 ] && [ \$2 -lt \$3 ]"
refute "brew bundle is not used"        grep -q '^brew bundle' "$LOG"
assert "gh-stack extension installed"   grep -q '^gh extension install github/gh-stack' "$LOG"
assert "cursor extensions installed"    grep -q '^cursor --install-extension esbenp.prettier-vscode' "$LOG"
assert "vscode extensions installed"    grep -q '^code --install-extension esbenp.prettier-vscode' "$LOG"
assert "mise config symlinked for bootstrap" test -L "$HOME/.config/mise/config.macos.toml"
assert "setup.sh installed manifest skills"  test "$(cat "$SK_DEST/foo/SKILL.md" 2>/dev/null)" = "v1"

refute "up-to-date mise is not upgraded" grep -q '^brew upgrade mise' "$LOG"
zsh "$REPO/setup.sh" > "$TMP/stub2.log" 2>&1
assert "second run exits 0 (idempotent)" test $? -eq 0

: > "$LOG"
STUB_MISE_VERSION=2026.9.1 zsh "$REPO/setup.sh" > "$TMP/stub_old.log" 2>&1
assert "old mise (2026.9.1) is upgraded via brew" grep -q '^brew upgrade mise' "$LOG"

: > "$LOG"
SETUP_LINKS_ONLY=1 zsh "$REPO/setup.sh" > "$TMP/stub3.log" 2>&1
assert "links-only run exits 0"         test $? -eq 0
assert "links-only runs only dotfiles"  grep -qE '^mise bootstrap --only dotfiles' "$LOG"
refute "links-only does not call gh/cursor/code/brew/sudo" grep -qE '^(gh|cursor|code|brew|sudo) ' "$LOG"

echo
echo "FAILS=$FAILS"
exit $((FAILS > 0))
