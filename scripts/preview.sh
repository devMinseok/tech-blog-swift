#!/usr/bin/env bash
# 초안을 포함해 블로그를 빌드하고, 로컬 서버로 띄운 뒤, 파일이 바뀌면 다시 빌드합니다.
# 사용법: ./scripts/preview.sh [포트]   (기본 포트 8000, 종료는 Ctrl+C)
set -euo pipefail

cd "$(dirname "$0")/.."
PORT="${1:-${PORT:-8000}}"
URL="http://127.0.0.1:${PORT}"

swift_is_new_enough() {
  local version
  version=$(swift --version 2>/dev/null | sed -nE 's/.*Swift version ([0-9]+)\.([0-9]+).*/\1 \2/p' | head -1)
  [[ -n "$version" ]] || return 1
  read -r major minor <<<"$version"
  ((major > 6 || (major == 6 && minor >= 3)))
}

# 기본 swift가 6.3보다 낮으면 설치된 Xcode 중 6.3 이상을 찾아 씁니다.
if ! swift_is_new_enough; then
  for xcode in $(ls -d /Applications/Xcode*.app 2>/dev/null | sort -r); do
    export DEVELOPER_DIR="$xcode/Contents/Developer"
    if swift_is_new_enough; then
      echo "→ Swift 6.3 이상이 있는 $(basename "$xcode")를 사용합니다."
      break
    fi
    unset DEVELOPER_DIR
  done
  swift_is_new_enough || { echo "Swift 6.3 이상이 필요합니다. Xcode 26.4 이상을 설치하세요." >&2; exit 1; }
fi

STAMP=$(mktemp)
SERVER_PID=""
cleanup() {
  [[ -n "$SERVER_PID" ]] && kill "$SERVER_PID" 2>/dev/null || true
  rm -f "$STAMP"
}
trap cleanup EXIT

build() {
  touch "$STAMP"
  echo "→ 빌드 중… ($(date +%H:%M:%S))"
  if swift run --quiet BlogBuilder --include-drafts --base-url "$URL" --base-path ""; then
    echo "✓ 완료. 브라우저를 새로고침하세요: $URL"
  else
    echo "✗ 빌드 실패. 위 오류를 고치고 저장하면 다시 빌드합니다."
  fi
}

build
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory .build/site >/dev/null 2>&1 &
SERVER_PID=$!
sleep 0.5
[[ -z "${NO_OPEN:-}" ]] && command -v open >/dev/null && open "$URL"
echo "→ $URL 에서 보는 중. Content, Public, Sources를 저장하면 자동으로 다시 빌드합니다. (종료: Ctrl+C)"

while sleep 1; do
  if [[ -n "$(find Content Public Sources -newer "$STAMP" -type f -print -quit 2>/dev/null)" ]]; then
    build
  fi
done
