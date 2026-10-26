#!/usr/bin/env bash
# 초안을 포함해 블로그를 빌드하고, 로컬 서버로 띄운 뒤, 파일을 저장하면 다시 빌드합니다.
# 보통은 `make preview`로 실행합니다. 종료는 Ctrl+C.
set -euo pipefail

cd "$(dirname "$0")/.."
PORT="${1:-${PORT:-8000}}"
URL="http://127.0.0.1:${PORT}"

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
if [[ -z "${NO_OPEN:-}" ]] && command -v open >/dev/null; then open "$URL"; fi
echo "→ $URL 에서 보는 중. Content, Public, Sources를 저장하면 자동으로 다시 빌드합니다. (종료: Ctrl+C)"

while sleep 1; do
  if [[ -n "$(find Content Public Sources -newer "$STAMP" -type f -print -quit 2>/dev/null)" ]]; then
    build
  fi
done
