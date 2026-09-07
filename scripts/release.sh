#!/usr/bin/env bash
# Builds a Release .app and zips it into dist/.
#
#   scripts/release.sh                 # ad-hoc signed (users must right-click > Open the first time)
#   SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" scripts/release.sh
#                                      # Developer ID signed; then notarize the zip (see README)
set -euo pipefail
cd "$(dirname "$0")/.."

SCHEME=claude-status
BUILD_DIR=build
DIST_DIR=dist
VERSION=$(sed -n 's/.*MARKETING_VERSION = \([0-9.]*\);.*/\1/p' claude-status.xcodeproj/project.pbxproj | head -1)

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$DIST_DIR"

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  SIGN_ARGS=(CODE_SIGN_IDENTITY="$SIGN_IDENTITY" CODE_SIGN_STYLE=Manual OTHER_CODE_SIGN_FLAGS="--timestamp" ENABLE_HARDENED_RUNTIME=YES CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO)
else
  SIGN_ARGS=(CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=)
fi

xcodebuild -project claude-status.xcodeproj -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath "$BUILD_DIR" "${SIGN_ARGS[@]}" build | grep -E 'error:|warning: .*\.swift|BUILD' || true

APP="$BUILD_DIR/Build/Products/Release/$SCHEME.app"
[[ -d "$APP" ]] || { echo "build failed: $APP not found"; exit 1; }

ZIP="$DIST_DIR/claude-status-$VERSION.zip"
ditto -c -k --keepParent "$APP" "$ZIP"
echo "-> $ZIP"
