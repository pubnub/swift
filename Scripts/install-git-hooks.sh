#!/usr/bin/env bash
# Points Git at the versioned hooks in .githooks.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
git config core.hooksPath .githooks
echo "Git hooks enabled (core.hooksPath=.githooks)."
