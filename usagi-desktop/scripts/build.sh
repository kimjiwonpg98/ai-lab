#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$PROJECT_DIR/dist/먼작귀 칭구들.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$PROJECT_DIR/.build/module-cache"
mkdir -p "$APP_DIR/Contents/Resources/DanceFrames"
cp "$PROJECT_DIR"/Assets/DanceFrames/frame-*.png "$APP_DIR/Contents/Resources/DanceFrames/"
mkdir -p "$APP_DIR/Contents/Resources/RakkoFrames"
cp "$PROJECT_DIR"/Assets/RakkoFrames/frame-*.png "$APP_DIR/Contents/Resources/RakkoFrames/"
for FRAMES in ChiikawaCryFrames ChiikawaSnackFrames ChiikawaCloverFrames ChiikawaDanceFrames; do
  mkdir -p "$APP_DIR/Contents/Resources/$FRAMES"
  cp "$PROJECT_DIR/Assets/$FRAMES/"frame-*.png "$APP_DIR/Contents/Resources/$FRAMES/"
done
cp "$PROJECT_DIR/Assets/usagi-dance.png" "$PROJECT_DIR/Assets/usagi-idle.png" "$APP_DIR/Contents/Resources/"
cp "$PROJECT_DIR/Assets/AppIcon.icns" "$APP_DIR/Contents/Resources/"
for ARCH in arm64 x86_64; do
  xcrun swiftc "$PROJECT_DIR/Sources/main.swift" -o "$PROJECT_DIR/.build/UsagiDesktop-$ARCH" \
    -target "$ARCH-apple-macos13.0" -framework AppKit -O \
    -module-cache-path "$PROJECT_DIR/.build/module-cache"
done
xcrun lipo -create "$PROJECT_DIR/.build/UsagiDesktop-arm64" "$PROJECT_DIR/.build/UsagiDesktop-x86_64" \
  -output "$APP_DIR/Contents/MacOS/UsagiDesktop"
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>UsagiDesktop</string>
<key>CFBundleIdentifier</key><string>local.playground.usagi-desktop</string>
<key>CFBundleName</key><string>먼작귀 칭구들</string>
<key>CFBundleDisplayName</key><string>먼작귀 칭구들</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.4.2</string>
<key>CFBundleVersion</key><string>7</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP_DIR"
printf 'Built: %s\n' "$APP_DIR"
