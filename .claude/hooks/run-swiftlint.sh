#!/bin/bash
# PostToolUse hook (Edit|Write): keeps Swift files SwiftLint-clean.
#
# Stays silent unless Claude has to act, to avoid polluting its context:
#   - Auto-fixable issues are fixed on disk without any output (the harness reports the modification itself).
#   - Remaining violations are printed on stderr with exit 2, so Claude fixes them.

INPUT=$(cat)

command -v jq >/dev/null 2>&1 || exit 0
command -v swiftlint >/dev/null 2>&1 || exit 0

FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")

[[ "$FILE_PATH" == *.swift && -f "$FILE_PATH" ]] || exit 0

cd "${CLAUDE_PROJECT_DIR:-$PWD}" || exit 0

# --force-exclude makes explicitly passed files honor `excluded:` in .swiftlint.yml
LINT_ARGS=(--quiet --force-exclude)

swiftlint --fix "${LINT_ARGS[@]}" "$FILE_PATH" >/dev/null 2>&1

# --strict so warnings count too; capture output instead of streaming it
OUTPUT=$(swiftlint lint --strict "${LINT_ARGS[@]}" "$FILE_PATH" 2>&1)

if [[ $? -ne 0 && -n "$OUTPUT" ]]; then
  {
    echo "SwiftLint violations remain; fix them:"
    echo "$OUTPUT" | sed "s|^$PWD/||"
  } >&2
  exit 2
fi

exit 0
