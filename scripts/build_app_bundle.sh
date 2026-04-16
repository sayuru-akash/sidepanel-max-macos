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
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

PLIST_TEMPLATE="$ROOT/$INFO_PLIST_PATH"
PLIST_OUTPUT="$CONTENTS_DIR/Info.plist"
EXECUTABLE_PATH="$ROOT/.build/release/$EXECUTABLE_NAME"
ICON_SOURCE="$ROOT/$ICON_SOURCE_PATH"
ENTITLEMENTS_FILE="$ROOT/$ENTITLEMENTS_PATH"

"$script_dir/sync_version_metadata.sh" >/dev/null

skip_build=false
for arg in "$@"; do
    case "$arg" in
        --skip-build)
            skip_build=true
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: ./scripts/build_app_bundle.sh [--skip-build]" >&2
            exit 1
            ;;
    esac
done

if [[ "$skip_build" == false ]]; then
    echo "[build_app_bundle] Building release executable..."
    swift build -c release --product "$EXECUTABLE_NAME"
fi

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
    echo "Release executable not found at $EXECUTABLE_PATH" >&2
    exit 1
fi

if [[ ! -f "$PLIST_TEMPLATE" ]]; then
    echo "Info.plist template not found at $PLIST_TEMPLATE" >&2
    exit 1
fi

echo "[build_app_bundle] Creating app bundle at $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$EXECUTABLE_PATH" "$MACOS_DIR/$EXECUTABLE_NAME"
chmod 755 "$MACOS_DIR/$EXECUTABLE_NAME"
cp "$PLIST_TEMPLATE" "$PLIST_OUTPUT"

/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" "$PLIST_OUTPUT"
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $EXECUTABLE_NAME" "$PLIST_OUTPUT"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $APP_BUNDLE_ID" "$PLIST_OUTPUT"
/usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" "$PLIST_OUTPUT"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST_OUTPUT"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$PLIST_OUTPUT"
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile $ICON_RESOURCE_NAME" "$PLIST_OUTPUT"
/usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion 14.0" "$PLIST_OUTPUT"

if [[ ! -f "$ICON_SOURCE" ]]; then
    echo "[build_app_bundle] Icon not found at $ICON_SOURCE" >&2
    echo "Run ./scripts/generate_icon.sh first." >&2
    exit 1
fi

cp "$ICON_SOURCE" "$RESOURCES_DIR/$ICON_FILE_NAME"

codesign_identity="${CODESIGN_IDENTITY:--}"
codesign_args=(--force --sign "$codesign_identity")

if [[ "$codesign_identity" != "-" ]]; then
    codesign_args+=(--timestamp --options runtime)
fi

if [[ -f "$ENTITLEMENTS_FILE" ]]; then
    codesign_args+=(--entitlements "$ENTITLEMENTS_FILE")
fi

echo "[build_app_bundle] Signing with identity: $codesign_identity"
codesign "${codesign_args[@]}" "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

echo "[build_app_bundle] App bundle ready: $APP_BUNDLE"
