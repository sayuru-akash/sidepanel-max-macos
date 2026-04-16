#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib/version.sh
source "$script_dir/lib/version.sh"
# shellcheck source=scripts/lib/project.sh
source "$script_dir/lib/project.sh"

ROOT="$(project_root)"
VERSION="$(read_version)"
PLIST_PATH="$ROOT/$INFO_PLIST_PATH"

if [[ ! -f "$PLIST_PATH" ]]; then
    echo "Info.plist not found at $PLIST_PATH" >&2
    exit 1
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST_PATH"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$PLIST_PATH"

echo "Synced Info.plist version metadata to $VERSION"
