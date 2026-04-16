#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib/version.sh
source "$script_dir/lib/version.sh"
# shellcheck source=scripts/lib/project.sh
source "$script_dir/lib/project.sh"

ROOT="$(project_root)"
VERSION="$(read_version)"

DIST_DIR="$ROOT/dist"
APP_BUNDLE="$DIST_DIR/${APP_NAME}.app"
UNSIGNED_PKG="$DIST_DIR/${APP_NAME}-${VERSION}-unsigned.pkg"
FINAL_PKG="$DIST_DIR/${APP_NAME}-${VERSION}.pkg"

skip_app_build=false
for arg in "$@"; do
    case "$arg" in
        --skip-app-build)
            skip_app_build=true
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: ./scripts/build_pkg.sh [--skip-app-build]" >&2
            exit 1
            ;;
    esac
done

if [[ "$skip_app_build" == false ]]; then
    "$script_dir/build_app_bundle.sh"
fi

if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "App bundle not found at $APP_BUNDLE" >&2
    exit 1
fi

mkdir -p "$DIST_DIR"
PKG_ROOT="$(mktemp -d "$DIST_DIR/pkg-root.XXXXXX")"

cleanup() {
    chmod -R u+w "$PKG_ROOT" >/dev/null 2>&1 || true
    rm -rf "$PKG_ROOT" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "[build_pkg] Building installer package for version $VERSION"
rm -f "$UNSIGNED_PKG" "$FINAL_PKG"
mkdir -p "$PKG_ROOT/Applications"

cp -R "$APP_BUNDLE" "$PKG_ROOT/Applications/${APP_NAME}.app"

pkgbuild \
    --root "$PKG_ROOT" \
    --identifier "${APP_BUNDLE_ID}.pkg" \
    --version "$VERSION" \
    --ownership preserve \
    --install-location "/" \
    "$UNSIGNED_PKG"

if [[ -n "${PKG_SIGN_IDENTITY:-}" ]]; then
    echo "[build_pkg] Signing installer with identity: $PKG_SIGN_IDENTITY"
    productsign --sign "$PKG_SIGN_IDENTITY" "$UNSIGNED_PKG" "$FINAL_PKG"
    rm -f "$UNSIGNED_PKG"
else
    mv "$UNSIGNED_PKG" "$FINAL_PKG"
fi

echo "[build_pkg] Installer ready: $FINAL_PKG"