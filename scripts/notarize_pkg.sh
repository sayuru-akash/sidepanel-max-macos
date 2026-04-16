#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib/version.sh
source "$script_dir/lib/version.sh"
# shellcheck source=scripts/lib/project.sh
source "$script_dir/lib/project.sh"

ROOT="$(project_root)"
VERSION="$(read_version)"

PKG_PATH="${1:-$ROOT/dist/${APP_NAME}-${VERSION}.pkg}"

if [[ ! -f "$PKG_PATH" ]]; then
    echo "Package file not found: $PKG_PATH" >&2
    exit 1
fi

: "${APPLE_ID:?APPLE_ID is required for notarization}"
: "${APPLE_TEAM_ID:?APPLE_TEAM_ID is required for notarization}"
: "${APPLE_APP_SPECIFIC_PASSWORD:?APPLE_APP_SPECIFIC_PASSWORD is required for notarization}"

echo "[notarize_pkg] Submitting $PKG_PATH for notarization"
xcrun notarytool submit "$PKG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait

echo "[notarize_pkg] Stapling notarization ticket"
xcrun stapler staple "$PKG_PATH"

echo "[notarize_pkg] Notarization complete"