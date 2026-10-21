#!/bin/bash
# Builds, installs to ~/Applications, and launches.
set -euo pipefail
cd "$(dirname "$0")"

./build.sh

TARGET="$HOME/Applications/Away.app"
mkdir -p "$HOME/Applications"
pkill -f "$TARGET/Contents/MacOS/Away" 2>/dev/null || true
sleep 0.5
if [ -d "$TARGET" ]; then
    rm -rf "$TARGET"
fi
ditto build/Away.app "$TARGET"
xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true
open "$TARGET"
echo "installed $TARGET"
