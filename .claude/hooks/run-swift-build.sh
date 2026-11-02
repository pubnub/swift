#!/bin/bash
#
# Stop hook: runs `swift build --build-tests` when Claude finishes a turn, so compile errors (including
# test targets broken by a Sources/ API change) that per-file SwiftLint cannot catch are fixed before
# control is handed back.
#
# Stays silent unless Claude has to act:
#   - No-op unless .swift files under Sources/ have changed (per git status).
#   - On failure the full log is saved to /tmp; only deduplicated, capped `error:` lines and the log path are printed on stderr with exit 2.
#
# Never blocks on its own failures:
#   - stop_hook_active=true: exit 0 immediately. Claude already got one chance to fix the errors in this
#     turn; blocking again could loop forever. The next turn's Stop hook reports them again.
#   - Missing swift/jq or a build exceeding BUILD_TIMEOUT: exit 0 with a one-line note. A concurrent
#     `swift build` holding the .build lock is covered by the same timeout.
#
# Limitation: a passing `swift build` does not guarantee that the Xcode build compiles.

MAX_ERRORS=15
BUILD_TIMEOUT=240 # must stay below the timeout in settings.json

INPUT=$(cat)

command -v jq >/dev/null 2>&1 || exit 0

if ! command -v swift >/dev/null 2>&1; then
  echo "swift not found; skipping swift build." >&2
  exit 0
fi

[[ "$(jq -r '.stop_hook_active // false' <<<"$INPUT")" == "true" ]] && exit 0

cd "${CLAUDE_PROJECT_DIR:-$PWD}" || exit 0
ROOT=$PWD

[[ -n "$(git status --porcelain -- 'Sources/*.swift' 2>/dev/null)" ]] || exit 0

LOG=$(mktemp /tmp/swift-build.XXXXXX) || exit 0

# `timeout` is not available on stock macOS, so use a watchdog
swift build --build-tests >"$LOG" 2>&1 &
BUILD_PID=$!
(
  sleep "$BUILD_TIMEOUT"
  pkill -TERM -P "$BUILD_PID" 2>/dev/null
  kill -TERM "$BUILD_PID" 2>/dev/null
) >/dev/null 2>&1 &
WATCHDOG_PID=$!

wait "$BUILD_PID"
STATUS=$?

if kill -0 "$WATCHDOG_PID" 2>/dev/null; then
  kill "$WATCHDOG_PID" 2>/dev/null
  wait "$WATCHDOG_PID" 2>/dev/null
elif [[ $STATUS -ne 0 ]]; then
  echo "swift build timed out after ${BUILD_TIMEOUT}s; skipping (log: $LOG)." >&2
  exit 0
fi

[[ $STATUS -eq 0 ]] && { rm -f "$LOG"; exit 0; }

ERRORS=$(grep -E '^[^ |].*: error: ' "$LOG" | sed "s|$ROOT/||g" | awk '!seen[$0]++')
TOTAL=$(grep -c . <<<"$ERRORS")

{
  echo "swift build failed; fix the errors (full log: $LOG):"
  if [[ -n "$ERRORS" ]]; then
    head -n "$MAX_ERRORS" <<<"$ERRORS"
    (( TOTAL > MAX_ERRORS )) && echo "... $((TOTAL - MAX_ERRORS)) more omitted"
  else
    echo "no 'error:' lines found; see the log."
  fi
} >&2
exit 2
