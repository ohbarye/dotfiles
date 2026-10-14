#!/bin/bash
# agents/skills.manifest に書かれた第三者 skill を、固定した ref で agents/skills/ に再現する。冪等。
#   SKILLS_MANIFEST  マニフェストのパス(既定: agents/skills.manifest)
#   SKILLS_DEST      配置先(既定: agents/skills)
#   SKILLS_GIT_BASE  リポジトリのベース URL(既定: https://github.com。テストで file:// に差し替える)
# 1 件でも失敗したら終了コードは 1(他の項目は続行する)。

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${SKILLS_MANIFEST:-$ROOT/agents/skills.manifest}"
DEST="${SKILLS_DEST:-$ROOT/agents/skills}"
BASE="${SKILLS_GIT_BASE:-https://github.com}"
MARKER=".manifest-ref"
status=0

[ -f "$MANIFEST" ] || { echo "install-skills: manifest not found: $MANIFEST" >&2; exit 1; }
mkdir -p "$DEST"

while read -r name repo path ref _; do
  case "$name" in ''|'#'*) continue ;; esac
  if [ -z "$ref" ]; then
    echo "install-skills: invalid entry for '$name' (need: name repo path ref)" >&2; status=1; continue
  fi

  want="$repo $path $ref"
  if [ -f "$DEST/$name/$MARKER" ] && [ "$(cat "$DEST/$name/$MARKER")" = "$want" ]; then
    echo "install-skills: up to date: $name ($ref)"
    continue
  fi

  tmp="$(mktemp -d)"
  if ! { git init -q "$tmp" \
      && git -C "$tmp" remote add origin "$BASE/$repo" \
      && git -C "$tmp" fetch -q --depth 1 --filter=blob:none origin "$ref" \
      && git -C "$tmp" sparse-checkout set "$path" \
      && git -C "$tmp" -c advice.detachedHead=false checkout -q FETCH_HEAD; } >/dev/null 2>&1; then
    echo "install-skills: failed to fetch $repo@$ref for '$name'" >&2
    status=1; rm -rf "$tmp"; continue
  fi
  if [ ! -f "$tmp/$path/SKILL.md" ]; then
    echo "install-skills: $path/SKILL.md not found in $repo@$ref ('$name')" >&2
    status=1; rm -rf "$tmp"; continue
  fi

  rm -rf "$DEST/$name"
  cp -R "$tmp/$path" "$DEST/$name"
  echo "$want" > "$DEST/$name/$MARKER"
  rm -rf "$tmp"
  echo "install-skills: installed $name ($repo@$ref)"
done < "$MANIFEST"

exit $status
