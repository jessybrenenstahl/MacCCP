#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${MACCCP_VERSION:-1.0.0}"
APP_BUNDLE="$ROOT_DIR/dist/MacCCP.app"
DMG_PATH="$ROOT_DIR/dist/MacCCP-$VERSION.dmg"

if [[ ! -d "$APP_BUNDLE" ]]; then
  "$ROOT_DIR/scripts/build_app.sh"
fi

rm -f "$DMG_PATH" "$DMG_PATH.sha256"
hdiutil create \
  -volname "MacCCP" \
  -srcfolder "$APP_BUNDLE" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

if [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait
  xcrun stapler staple "$DMG_PATH"
fi

(cd "$ROOT_DIR/dist" && shasum -a 256 "$(basename "$DMG_PATH")" > "$(basename "$DMG_PATH").sha256")
echo "$DMG_PATH"
