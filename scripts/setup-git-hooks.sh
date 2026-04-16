#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib/version.sh
source "$script_dir/lib/version.sh"

ROOT="$(project_root)"

git -C "$ROOT" config core.hooksPath .githooks
chmod +x "$ROOT/.githooks/pre-commit"

echo "Configured git hooks path to .githooks"