#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET="$PROJECT_DIR/.build/AppIcon.iconset"
mkdir -p "$ICONSET" "$PROJECT_DIR/.build/module-cache"
xcrun swiftc -module-cache-path "$PROJECT_DIR/.build/module-cache" -framework AppKit \
  "$PROJECT_DIR/scripts/make-icon.swift" -o "$PROJECT_DIR/.build/make-icon"
"$PROJECT_DIR/.build/make-icon" "$PROJECT_DIR/Assets/app-icon-source.webp" \
  "$PROJECT_DIR/Assets/app-icon.png"
for SIZE in 16 32 128 256 512; do
  sips -z "$SIZE" "$SIZE" "$PROJECT_DIR/Assets/app-icon.png" \
    --out "$ICONSET/icon_${SIZE}x${SIZE}.png" >/dev/null
  DOUBLE=$((SIZE * 2))
  sips -z "$DOUBLE" "$DOUBLE" "$PROJECT_DIR/Assets/app-icon.png" \
    --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$PROJECT_DIR/Assets/AppIcon.icns"
