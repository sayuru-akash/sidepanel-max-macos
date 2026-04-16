#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib/version.sh
source "$script_dir/lib/version.sh"

ROOT="$(project_root)"
NEW_VERSION="${1:-}"

if [[ -z "$NEW_VERSION" ]]; then
    echo "Usage: ./scripts/bump_version.sh <major.minor.patch>" >&2
    exit 1
fi

if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid version '$NEW_VERSION'. Expected semantic version, e.g. 0.1.1" >&2
    exit 1
fi

printf '%s\n' "$NEW_VERSION" > "$ROOT/version.txt"
"$script_dir/sync_version_metadata.sh"
echo "version.txt updated to $NEW_VERSION"
