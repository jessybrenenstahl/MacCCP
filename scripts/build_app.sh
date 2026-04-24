#!/usr/bin/env bash
set -euo pipefail

APP_NAME="MacCCP"
DISPLAY_NAME="MacCCP"
BUNDLE_ID="app.macccp.player"
MIN_SYSTEM_VERSION="${MACCCP_MIN_SYSTEM_VERSION:-14.0}"
CONFIGURATION="${CONFIGURATION:-release}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$DISPLAY_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_FRAMEWORKS="$APP_CONTENTS/Frameworks"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ICON_SOURCE="$ROOT_DIR/Resources/AppIcon.icns"

mkdir -p "$DIST_DIR"

swift build -c "$CONFIGURATION"
BUILD_BINARY="$(swift build -c "$CONFIGURATION" --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$APP_FRAMEWORKS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod u+w "$APP_BINARY"
chmod +x "$APP_BINARY"

if [[ -f "$ICON_SOURCE" ]]; then
  cp "$ICON_SOURCE" "$APP_RESOURCES/AppIcon.icns"
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${MACCCP_VERSION:-1.0.0}</string>
  <key>CFBundleVersion</key>
  <string>${MACCCP_BUILD_NUMBER:-1}</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.video</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>MacCCP is GPL software built on libmpv, FFmpeg, and libass.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeName</key>
      <string>Media Files</string>
      <key>CFBundleTypeRole</key>
      <string>Viewer</string>
      <key>LSHandlerRank</key>
      <string>Alternate</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>public.movie</string>
        <string>public.video</string>
        <string>public.audio</string>
        <string>public.audiovisual-content</string>
        <string>public.mpeg-4</string>
        <string>com.apple.quicktime-movie</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
PLIST

install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BINARY" 2>/dev/null || true

is_bundle_dependency() {
  local dependency="$1"
  [[ "$dependency" == /opt/homebrew/* || "$dependency" == /usr/local/* ]]
}

bundle_dependency() {
  local source="$1"
  [[ -f "$source" ]] || return 0
  is_bundle_dependency "$source" || return 0

  local basename
  basename="$(basename "$source")"
  local destination="$APP_FRAMEWORKS/$basename"

  if [[ ! -f "$destination" ]]; then
    cp -L "$source" "$destination"
    chmod u+w "$destination"
    install_name_tool -id "@rpath/$basename" "$destination" 2>/dev/null || true

    while read -r nested; do
      [[ -n "$nested" ]] || continue
      bundle_dependency "$nested"
      if is_bundle_dependency "$nested"; then
        install_name_tool -change "$nested" "@rpath/$(basename "$nested")" "$destination" 2>/dev/null || true
      fi
    done < <(otool -L "$destination" | awk 'NR > 1 {print $1}')
  fi
}

while read -r dependency; do
  [[ -n "$dependency" ]] || continue
  bundle_dependency "$dependency"
  if is_bundle_dependency "$dependency"; then
    install_name_tool -change "$dependency" "@rpath/$(basename "$dependency")" "$APP_BINARY" 2>/dev/null || true
  fi
done < <(otool -L "$APP_BINARY" | awk 'NR > 1 {print $1}')

SIGN_IDENTITY="${MACCCP_CODESIGN_IDENTITY:--}"
SIGN_ARGS=(--force --sign "$SIGN_IDENTITY")
if [[ "$SIGN_IDENTITY" != "-" ]]; then
  SIGN_ARGS=(--force --options runtime --entitlements "$ROOT_DIR/Resources/MacCCP.entitlements" --sign "$SIGN_IDENTITY")
elif [[ "${MACCCP_REQUIRE_NOTARIZATION:-0}" == "1" ]]; then
  echo "MACCCP_CODESIGN_IDENTITY must be set for a production notarized release" >&2
  exit 2
fi

while IFS= read -r binary; do
  if file "$binary" | grep -q "Mach-O"; then
    codesign "${SIGN_ARGS[@]}" "$binary"
  fi
done < <(find "$APP_FRAMEWORKS" -type f)

codesign "${SIGN_ARGS[@]}" "$APP_BINARY"
codesign "${SIGN_ARGS[@]}" "$APP_BUNDLE"
plutil -lint "$INFO_PLIST"

echo "$APP_BUNDLE"
