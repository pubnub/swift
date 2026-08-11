#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip non-Swift files
if [[ "$FILE_PATH" != *.swift ]]; then
  exit 0
fi

# Auto-fix what we can
swiftlint --fix "$FILE_PATH" 2>/dev/null

# Validate remaining violations (--strict so warnings block too)
OUTPUT=$(swiftlint --strict "$FILE_PATH" 2>&1)
if [[ $? -ne 0 ]]; then
  echo "SwiftLint violations remain in $FILE_PATH" >&2
  echo "$OUTPUT" >&2
  exit 2
fi

exit 0
