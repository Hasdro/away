#!/bin/bash
# Builds Away.app, runs the schedule tests first, and can render design previews.
#   ./build.sh          build
#   ./build.sh render   build, then write build/previews/*.png
set -euo pipefail
cd "$(dirname "$0")"

APP="Away"
BUILD="$PWD/build"
BUNDLE="$BUILD/$APP.app"
ARCH="$(uname -m)"
TARGET="$ARCH-apple-macos14.0"

SOURCES=(
    Sources/Theme.swift
    Sources/Prefs.swift
    Sources/Schedule.swift
    Sources/Idle.swift
    Sources/BreakView.swift
    Sources/Overlay.swift
    Sources/StatusIcon.swift
    Sources/SettingsView.swift
    Sources/AppDelegate.swift
    Sources/PreviewRenderer.swift
    Sources/main.swift
)

mkdir -p "$BUILD"

echo "==> schedule tests"
swiftc -swift-version 5 -Onone Sources/Schedule.swift Tests/ScheduleTests.swift -o "$BUILD/schedule-tests"
"$BUILD/schedule-tests"

echo "==> icon"
swiftc -O Tools/makeicon.swift -o "$BUILD/makeicon"
"$BUILD/makeicon" "$BUILD/icon-1024.png" >/dev/null
ICONSET="$BUILD/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$BUILD/icon-1024.png" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" "$BUILD/icon-1024.png" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$BUILD/AppIcon.icns"

echo "==> app"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
swiftc -swift-version 5 -O -whole-module-optimization \
    -target "$TARGET" \
    -o "$BUNDLE/Contents/MacOS/$APP" \
    "${SOURCES[@]}"
cp Resources/Info.plist "$BUNDLE/Contents/Info.plist"
plutil -lint "$BUNDLE/Contents/Info.plist" >/dev/null
cp "$BUILD/AppIcon.icns" "$BUNDLE/Contents/Resources/AppIcon.icns"
printf 'APPL????' > "$BUNDLE/Contents/PkgInfo"
codesign --force --sign - --timestamp=none "$BUNDLE" >/dev/null
echo "built $BUNDLE"

if [ "${1:-}" = "render" ]; then
    "$BUNDLE/Contents/MacOS/$APP" --render "$BUILD/previews"
    swiftc -swift-version 5 -target "$TARGET" \
        Sources/Theme.swift Sources/Schedule.swift Sources/Prefs.swift \
        Sources/SettingsView.swift Tools/shot.swift \
        -o "$BUILD/shot"
    "$BUILD/shot" "$BUILD/previews/settings-light.png"
    "$BUILD/shot" --dark "$BUILD/previews/settings-dark.png"
fi
