#!/bin/bash
#
# PostToolUse hook (Edit|Write): tidies up Swift files with SwiftLint after every edit.
#
# It only speaks up when Claude needs to do something, so the context stays clean:
#   - Anything SwiftLint can fix on its own is fixed quietly (the harness already reports the file change).
#   - Anything left over is printed on stderr with exit 2, so Claude can fix it by hand.

INPUT=$(cat)

command -v jq >/dev/null 2>&1 || exit 0
command -v swiftlint >/dev/null 2>&1 || exit 0

FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")

[[ "$FILE_PATH" == *.swift && -f "$FILE_PATH" ]] || exit 0

cd "${CLAUDE_PROJECT_DIR:-$PWD}" || exit 0

# Without --force-exclude, SwiftLint would lint a file we pass by name even if .swiftlint.yml excludes it
LINT_ARGS=(--quiet --force-exclude)

swiftlint --fix "${LINT_ARGS[@]}" "$FILE_PATH" >/dev/null 2>&1

# Lint in strict mode so warnings aren't ignored; the output is captured rather than printed straight away
OUTPUT=$(swiftlint lint --strict "${LINT_ARGS[@]}" "$FILE_PATH" 2>&1)

if [[ $? -ne 0 && -n "$OUTPUT" ]]; then
  {
    echo "SwiftLint violations remain; fix them:"
    echo "$OUTPUT" | sed "s|^$PWD/||"
  } >&2
  exit 2
fi

exit 0
