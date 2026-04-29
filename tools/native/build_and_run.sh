#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="TodoListApp"
DISPLAY_NAME="Todo"
BUNDLE_ID="com.sky.todolistapp"
MIN_SYSTEM_VERSION="15.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/apple/TodoList"
DIST_DIR="$ROOT_DIR/dist/native"
APP_BUNDLE="$DIST_DIR/$DISPLAY_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ICON_SOURCE="$ROOT_DIR/tauri/src-tauri/icons/icon.icns"
LOCAL_SIGNING_SETUP="$ROOT_DIR/tools/native/setup_local_signing.sh"
LOCAL_SIGNING_ENV="$HOME/Library/Application Support/com.todolist.app/local-signing/env.sh"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build --package-path "$PACKAGE_DIR"
BUILD_BINARY="$(swift build --package-path "$PACKAGE_DIR" --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE" "$DIST_DIR/$APP_NAME.app"
mkdir -p "$APP_MACOS"
mkdir -p "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$ICON_SOURCE" "$APP_RESOURCES/icon.icns"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleDisplayName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundleIconFile</key>
  <string>icon.icns</string>
  <key>CFBundleName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ -x "$LOCAL_SIGNING_SETUP" ]]; then
  "$LOCAL_SIGNING_SETUP" --quiet
fi

if [[ -f "$LOCAL_SIGNING_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$LOCAL_SIGNING_ENV"
fi

if [[ -n "${TODO_LIST_SIGNING_IDENTITY_HASH:-}" ]]; then
  codesign --force --deep --sign "$TODO_LIST_SIGNING_IDENTITY_HASH" \
    --keychain "${TODO_LIST_SIGNING_KEYCHAIN:-}" \
    "$APP_BUNDLE"
elif [[ -n "${TODO_LIST_SIGNING_IDENTITY:-}" ]]; then
  codesign --force --deep --sign "$TODO_LIST_SIGNING_IDENTITY" \
    --keychain "${TODO_LIST_SIGNING_KEYCHAIN:-}" \
    "$APP_BUNDLE"
else
  codesign --force --deep --sign - "$APP_BUNDLE"
fi

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
