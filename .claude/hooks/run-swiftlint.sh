#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip non-Swift files
if [[ "$FILE_PATH" != *.swift ]]; then
  exit 0
fi

# Skip when SwiftLint isn't installed, rather than blocking every Swift edit
if ! command -v swiftlint >/dev/null 2>&1; then
  exit 0
fi

# Auto-fix what we can. This rewrites the file after the write, so report it:
# the on-disk result can differ from what was just written.
BEFORE=$(shasum "$FILE_PATH" 2>/dev/null)
swiftlint --fix "$FILE_PATH" 2>/dev/null
if [[ "$(shasum "$FILE_PATH" 2>/dev/null)" != "$BEFORE" ]]; then
  echo "SwiftLint --fix reformatted $FILE_PATH; re-read it before further edits"
fi

# Validate remaining violations (--strict so warnings block too)
OUTPUT=$(swiftlint --strict "$FILE_PATH" 2>&1)
if [[ $? -ne 0 ]]; then
  echo "SwiftLint violations remain in $FILE_PATH" >&2
  echo "$OUTPUT" >&2
  exit 2
fi

exit 0
