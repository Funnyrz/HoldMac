#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
APP_NAME="${APP_NAME:-文件中转桶}"
APP_PATH="${APP_PATH:-$BUILD_DIR/$APP_NAME.app}"
DIST_DIR="${DIST_DIR:-$BUILD_DIR/dist}"
STAGING_DIR="$BUILD_DIR/dmg-staging"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found: $APP_PATH" >&2
  echo "Run 'make app' before building the DMG." >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
DMG_NAME="${DMG_NAME:-HoldMac-$VERSION.dmg}"
DMG_PATH="$DIST_DIR/$DMG_NAME"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR" "$DIST_DIR"

cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "Created $DMG_PATH"
echo
echo "If macOS blocks the app after installation, run:"
echo "  xattr -dr com.apple.quarantine \"/Applications/$APP_NAME.app\""
