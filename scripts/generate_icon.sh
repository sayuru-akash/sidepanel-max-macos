#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib/version.sh
source "$script_dir/lib/version.sh"

ROOT="$(project_root)"
ICON_DIR="$ROOT/Assets/AppIcon"
ICONSET_DIR="$ICON_DIR/SidePanel.iconset"
PNG_1024="$ICON_DIR/SidePanel-1024.png"
ICNS_OUT="$ICON_DIR/SidePanel.icns"

mkdir -p "$ICON_DIR"

swift "$script_dir/generate_icon.swift" "$PNG_1024"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$PNG_1024" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
    sips -z "$((size * 2))" "$((size * 2))" "$PNG_1024" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done

cp "$PNG_1024" "$ICONSET_DIR/icon_512x512@2x.png"
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_OUT"
rm -rf "$ICONSET_DIR"

echo "Generated app icon: $ICNS_OUT"