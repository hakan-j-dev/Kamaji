#!/usr/bin/env bash
# Kamaji 세팅 스크립트. 대상 프로젝트 루트에서 실행한다.
#
#   install.sh                 GitHub에서 받아 설치 (재실행하면 업데이트)
#   install.sh --uninstall     설치한 것을 걷어냄
#   install.sh --source DIR    로컬 Kamaji 저장소에서 설치 (개발·검증용)
#   install.sh --target DIR    현재 폴더 대신 DIR에 설치
#
# 환경 변수: KAMAJI_REPO (소유자/이름, 기본 hakan-j-dev/Kamaji), KAMAJI_REF (브랜치·태그, 기본 main)
set -euo pipefail

KAMAJI_REPO="${KAMAJI_REPO:-hakan-j-dev/Kamaji}"
KAMAJI_REF="${KAMAJI_REF:-main}"
START_MARK="<!-- kamaji:start -->"
END_MARK="<!-- kamaji:end -->"
CLAUDE_MARK="<!-- kamaji -->"

mode="install"
source_dir=""
target="$PWD"

while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) mode="uninstall" ;;
    --source) source_dir="$2"; shift ;;
    --target) target="$2"; shift ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "알 수 없는 옵션: $1" >&2; exit 1 ;;
  esac
  shift
done

[ -d "$target" ] || { echo "대상 폴더가 없음: $target" >&2; exit 1; }
target="$(cd "$target" && pwd)"

if [ -f "$target/install.sh" ] && [ -f "$target/kamaji/entry.md" ]; then
  echo "Kamaji 저장소 자체에는 설치하지 않음: $target" >&2
  exit 1
fi

agents="$target/AGENTS.md"
claude="$target/CLAUDE.md"

# 파일 끝의 빈 줄을 지우고, 내용이 비면 파일을 삭제한다.
tidy() {
  local f="$1" tmp
  tmp="$(mktemp)"
  awk '{ lines[NR] = $0 } END { n = NR; while (n > 0 && lines[n] ~ /^[[:space:]]*$/) n--; for (i = 1; i <= n; i++) print lines[i] }' "$f" > "$tmp"
  if [ -s "$tmp" ]; then mv "$tmp" "$f"; else rm -f "$tmp" "$f"; fi
}

remove_agents_block() {
  [ -f "$agents" ] && grep -qF "$START_MARK" "$agents" || return 0
  local tmp
  tmp="$(mktemp)"
  awk -v s="$START_MARK" -v e="$END_MARK" '$0 == s { skip = 1; next } $0 == e { skip = 0; next } !skip' "$agents" > "$tmp"
  mv "$tmp" "$agents"
  tidy "$agents"
}

remove_claude_import() {
  [ -f "$claude" ] && [ ! -L "$claude" ] && grep -qxF "$CLAUDE_MARK" "$claude" || return 0
  local tmp
  tmp="$(mktemp)"
  awk -v m="$CLAUDE_MARK" '$0 == m { drop = 1; next } drop == 1 && $0 == "@AGENTS.md" { drop = 2; next } drop == 2 && $0 ~ /^[[:space:]]*$/ { drop = 0; next } { drop = 0; print }' "$claude" > "$tmp"
  mv "$tmp" "$claude"
  tidy "$claude"
}

if [ "$mode" = "uninstall" ]; then
  remove_agents_block
  remove_claude_import
  rm -rf "$target/.kamaji"
  echo "Kamaji 제거 완료: $target"
  exit 0
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

if [ -n "$source_dir" ]; then
  src="$(cd "$source_dir" && pwd)/kamaji"
  origin="local:$(cd "$source_dir" && pwd)"
else
  curl -fsSL "https://codeload.github.com/$KAMAJI_REPO/tar.gz/$KAMAJI_REF" | tar -xz -C "$workdir"
  src="$(find "$workdir" -mindepth 2 -maxdepth 2 -type d -name kamaji | head -n 1)"
  origin="github:$KAMAJI_REPO@$KAMAJI_REF"
fi
[ -f "$src/entry.md" ] || { echo "Kamaji 본체를 찾지 못함: $src" >&2; exit 1; }

# 1. 본체 복사. 기존 .kamaji/는 통째로 교체한다.
rm -rf "$target/.kamaji"
cp -R "$src" "$target/.kamaji"
printf 'source=%s\n' "$origin" > "$target/.kamaji/.installed"

# 2. AGENTS.md: 표시 사이의 블록만 교체하고, 블록이 없으면 끝에 덧붙인다.
block="$workdir/block.md"
{ echo "$START_MARK"; cat "$src/entry.md"; echo "$END_MARK"; } > "$block"
if [ -f "$agents" ] && grep -qF "$START_MARK" "$agents"; then
  tmp="$(mktemp)"
  awk -v s="$START_MARK" -v e="$END_MARK" -v b="$block" '
    $0 == s { while ((getline line < b) > 0) print line; skip = 1; next }
    $0 == e { skip = 0; next }
    !skip' "$agents" > "$tmp"
  mv "$tmp" "$agents"
elif [ -s "$agents" ]; then
  { echo; cat "$block"; } >> "$agents"
else
  cp "$block" "$agents"
fi

# 3. CLAUDE.md: AGENTS.md를 이미 불러오거나 심볼릭 링크면 건드리지 않는다.
if [ -L "$claude" ]; then
  echo "CLAUDE.md가 심볼릭 링크라 건드리지 않음"
elif [ -f "$claude" ] && grep -qxE '@(\./)?AGENTS\.md[[:space:]]*' "$claude"; then
  :
elif [ -s "$claude" ]; then
  tmp="$(mktemp)"
  { echo "$CLAUDE_MARK"; echo "@AGENTS.md"; echo; cat "$claude"; } > "$tmp"
  mv "$tmp" "$claude"
else
  { echo "$CLAUDE_MARK"; echo "@AGENTS.md"; } > "$claude"
fi

echo "Kamaji 설치 완료: $target ($origin)"
