#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib/version.sh
source "$script_dir/lib/version.sh"

ROOT="$(project_root)"
VERSION="$(read_version)"

echo "[check] Running production checks for version $VERSION"
cd "$ROOT"

echo "[check] sync version metadata"
"$script_dir/sync_version_metadata.sh"

echo "[check] swift test"
swift test

echo "[check] swift build -c release"
swift build -c release --product SidePanel

echo "[check] build app bundle"
"$script_dir/build_app_bundle.sh" --skip-build

echo "[check] build installer package"
"$script_dir/build_pkg.sh" --skip-app-build

echo "[check] All checks passed"
