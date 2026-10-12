#!/bin/bash
# macOS のシステム設定を defaults write で再現する。冪等。macOS 以外では何もしない。
# 現在のマシンで明示的に変更している値だけを書いている(未設定の項目は OS 既定のまま)。
# 使い方: ./macos.sh        (DRY_RUN=1 で実行内容の表示のみ)

set -u

if [ "$(uname -s)" != "Darwin" ]; then
  echo "macos.sh: not macOS, skipping"
  exit 0
fi

run() {
  if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "+ $*"
  else
    "$@"
  fi
}

# Dock
run defaults write com.apple.dock autohide -bool true
run defaults write com.apple.dock tilesize -int 64
run defaults write com.apple.dock orientation -string right

# Finder (clmv = カラム表示)
run defaults write com.apple.finder FXPreferredViewStyle -string clmv

# キーボード
run defaults write NSGlobalDomain KeyRepeat -int 2
run defaults write NSGlobalDomain InitialKeyRepeat -int 15
run defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# 自動修正・自動置換を無効化
run defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
run defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
run defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
run defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
run defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# トラックパッド: タップでクリック
run defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# メニューバーの時計に秒を表示
run defaults write com.apple.menuextra.clock ShowSeconds -bool true

# 反映のため再起動(未起動でも失敗させない)
for app in Dock Finder SystemUIServer; do
  run killall "$app" || true
done
