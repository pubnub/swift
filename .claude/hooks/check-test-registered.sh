#!/bin/bash
# PostToolUse hook (Edit|Write): warns when a test file is missing from PubNub.xcodeproj.
#
# Test files that are not registered in project.pbxproj compile nowhere and never run in CI, while
# `swift build` and SwiftLint still pass.
#
# Stays silent unless Claude has to act:
#   - Prints one line on stderr with exit 2 when the file is not referenced in project.pbxproj.
#   - Never blocks on its own failures (missing jq, unreadable pbxproj).

INPUT=$(cat)

command -v jq >/dev/null 2>&1 || exit 0

FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")

[[ "$FILE_PATH" == *.swift && -f "$FILE_PATH" ]] || exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
PBXPROJ="$ROOT/PubNub.xcodeproj/project.pbxproj"

[[ -r "$PBXPROJ" ]] || exit 0

# Contract tests are CI-managed and intentionally not covered
case "$FILE_PATH" in
  "$ROOT"/Tests/PubNubUnitTests/*) TARGET="PubNubTests" ;;
  "$ROOT"/Tests/PubNubIntegrationTests/*) TARGET="PubNubIntegration" ;;
  *) exit 0 ;;
esac

# Fixed-string match on the file name, which is how pbxproj references sources
if ! grep -qF -- "$(basename "$FILE_PATH")" "$PBXPROJ" 2>/dev/null; then
  echo "${FILE_PATH#"$ROOT"/} is not in PubNub.xcodeproj/project.pbxproj; add it to the $TARGET target." >&2
  exit 2
fi

exit 0
