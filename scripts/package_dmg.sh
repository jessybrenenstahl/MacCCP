#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${MACCCP_VERSION:-1.0.0}"
APP_BUNDLE="$ROOT_DIR/dist/MacCCP.app"
DMG_PATH="$ROOT_DIR/dist/MacCCP-$VERSION.dmg"

if [[ ! -d "$APP_BUNDLE" ]]; then
  "$ROOT_DIR/scripts/build_app.sh"
fi

if [[ "${MACCCP_REQUIRE_NOTARIZATION:-0}" == "1" ]]; then
  if [[ -z "${APPLE_ID:-}" || -z "${APPLE_TEAM_ID:-}" || -z "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
    echo "APPLE_ID, APPLE_TEAM_ID, and APPLE_APP_SPECIFIC_PASSWORD are required for notarized production releases" >&2
    exit 2
  fi

  if [[ -z "${MACCCP_CODESIGN_IDENTITY:-}" || "${MACCCP_CODESIGN_IDENTITY:-}" == "-" ]]; then
    echo "MACCCP_CODESIGN_IDENTITY is required for notarized production releases" >&2
    exit 2
  fi
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
