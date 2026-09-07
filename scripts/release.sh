#!/usr/bin/env bash
# Builds, signs, notarizes and (optionally) publishes a release.
#
#   scripts/release.sh                  build + notarize → dist/claude-status-<version>.zip
#   scripts/release.sh 1.1              same, after bumping MARKETING_VERSION to 1.1 and committing
#   scripts/release.sh 1.1 --publish    ... then tag v1.1, push, and create the GitHub release
#
# Environment:
#   SIGN_IDENTITY   "Developer ID Application: Name (TEAMID)". Auto-detected from the keychain;
#                   if none is found the app is ad-hoc signed and notarization is skipped.
#   NOTARY_PROFILE  notarytool keychain profile (default: notary), created once with
#                   xcrun notarytool store-credentials notary --apple-id <email> --team-id <TEAMID>
#   DEVELOPER_DIR   Xcode to use. Defaults to Xcode-beta.app when the selected Xcode is older than 26.
set -euo pipefail
cd "$(dirname "$0")/.."

SCHEME=claude-status
PROJECT=claude-status.xcodeproj
BUILD_DIR=build
DIST_DIR=dist
NOTARY_PROFILE=${NOTARY_PROFILE:-notary}

NEW_VERSION=""
PUBLISH=0
for arg in "$@"; do
  case "$arg" in
    --publish) PUBLISH=1 ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) NEW_VERSION=$arg ;;
  esac
done

log() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
die() { echo "error: $*" >&2; exit 1; }

# --- toolchain ---------------------------------------------------------------
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode-beta.app ]]; then
  major=$( (xcodebuild -version 2>/dev/null || true) | sed -n 's/^Xcode \([0-9]*\).*/\1/p')
  if [[ -z "$major" || "$major" -lt 26 ]]; then
    export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
  fi
fi

# --- version -----------------------------------------------------------------
current_version() {
  sed -n 's/.*MARKETING_VERSION = \([0-9.]*\);.*/\1/p' "$PROJECT/project.pbxproj" | head -1
}
VERSION=$(current_version)

if [[ -n "$NEW_VERSION" && "$NEW_VERSION" != "$VERSION" ]]; then
  log "Bumping version $VERSION → $NEW_VERSION"
  [[ -z "$(git status --porcelain)" ]] || die "working tree is dirty; commit or stash before bumping the version"
  sed -i '' "s/MARKETING_VERSION = $VERSION;/MARKETING_VERSION = $NEW_VERSION;/g" "$PROJECT/project.pbxproj"
  git commit -q -m "chore: release v$NEW_VERSION" -- "$PROJECT/project.pbxproj"
  VERSION=$NEW_VERSION
fi
TAG="v$VERSION"

if [[ $PUBLISH -eq 1 ]]; then
  [[ -z "$(git status --porcelain)" ]] || die "working tree is dirty; commit before publishing"
  git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && die "tag $TAG already exists; delete it first (gh release delete $TAG --cleanup-tag)"
  gh auth status >/dev/null 2>&1 || die "gh is not logged in"
fi

# --- signing identity --------------------------------------------------------
if [[ -z "${SIGN_IDENTITY:-}" ]]; then
  SIGN_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null \
    | sed -n 's/.*"\(Developer ID Application: [^"]*\)".*/\1/p' | head -1)
fi
if [[ -n "$SIGN_IDENTITY" ]]; then
  SIGN_ARGS=(CODE_SIGN_IDENTITY="$SIGN_IDENTITY" CODE_SIGN_STYLE=Manual
             OTHER_CODE_SIGN_FLAGS="--timestamp" ENABLE_HARDENED_RUNTIME=YES
             CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO)
  NOTARIZE=1
else
  echo "no Developer ID identity found: ad-hoc signing, users must right-click > Open the first time"
  SIGN_ARGS=(CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=)
  NOTARIZE=0
fi

# --- build -------------------------------------------------------------------
log "Building $SCHEME $VERSION (${SIGN_IDENTITY:-ad-hoc})"
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$DIST_DIR"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath "$BUILD_DIR" "${SIGN_ARGS[@]}" build \
  2>&1 | grep -E 'error:|warning: .*\.swift|BUILD' || true

APP="$BUILD_DIR/Build/Products/Release/$SCHEME.app"
[[ -d "$APP" ]] || die "build failed: $APP not found"
ZIP="$DIST_DIR/$SCHEME-$VERSION.zip"
zip_app() { rm -f "$ZIP"; ditto -c -k --keepParent "$APP" "$ZIP"; }
zip_app

# --- notarize ----------------------------------------------------------------
if [[ $NOTARIZE -eq 1 ]]; then
  log "Notarizing $ZIP"
  out=$(xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait 2>&1) || true
  echo "$out" | grep -E '^\s*(id|status):' | tail -2
  if ! echo "$out" | grep -q 'status: Accepted'; then
    id=$(echo "$out" | sed -n 's/^ *id: //p' | head -1)
    [[ -n "$id" ]] && xcrun notarytool log "$id" --keychain-profile "$NOTARY_PROFILE"
    die "notarization failed"
  fi
  xcrun stapler staple -q "$APP"
  zip_app   # stapling modifies the app, so the zip must be rebuilt
fi

# --- verify ------------------------------------------------------------------
log "Verifying"
lipo -info "$APP/Contents/MacOS/$SCHEME" | sed 's/.*are: /architectures: /'
codesign --verify --deep --strict "$APP"
if [[ $NOTARIZE -eq 1 ]]; then
  spctl -a -vv -t exec "$APP" 2>&1 | grep -q 'Notarized Developer ID' || die "Gatekeeper does not accept the app"
  echo "gatekeeper: Notarized Developer ID"
fi
echo "-> $ZIP ($(du -h "$ZIP" | cut -f1))"

# --- publish -----------------------------------------------------------------
if [[ $PUBLISH -eq 1 ]]; then
  log "Publishing $TAG"
  git tag "$TAG"
  git push -q origin HEAD "$TAG"
  gh release create "$TAG" "$ZIP" --title "$TAG" --generate-notes
fi
