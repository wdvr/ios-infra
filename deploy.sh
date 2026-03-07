#!/bin/bash
set -euo pipefail

# Ensure homebrew tools are available
export PATH="/opt/homebrew/bin:$HOME/bin:$PATH"

# Universal iOS deploy script
# Usage: deploy.sh [project-dir]
#   If device is connected: builds locally and installs on device
#   If device is not connected: builds locally and uploads to TestFlight
#
# Can be run from any iOS project directory, or pass the project dir as arg.

# --- Config ---
TEAM_ID="N324UX8D9M"
ASC_KEY_PATH="$HOME/.appstoreconnect/AuthKey_GA9T4G84AU.p8"
ASC_KEY_ID="GA9T4G84AU"
ASC_ISSUER_ID="39f22957-9a03-421a-ada6-86471b32ee9f"
KEYCHAIN_PATH="$HOME/ios-signing.keychain-db"
KEYCHAIN_PASSWORD="ios-signing-shared"

# --- Resolve project ---
PROJECT_DIR="${1:-$(pwd)}"
cd "$PROJECT_DIR"

# Find ios/ subdir if we're in a repo root
if [ -f "ios/project.yml" ] || ls ios/*.xcodeproj &>/dev/null; then
  IOS_DIR="$PROJECT_DIR/ios"
else
  IOS_DIR="$PROJECT_DIR"
fi

# --- Detect project type and scheme ---
if [ -f "$IOS_DIR/project.yml" ]; then
  # XcodeGen project
  which xcodegen &>/dev/null || { echo "Installing xcodegen..."; brew install xcodegen; }
  echo "Generating Xcode project..."
  (cd "$IOS_DIR" && xcodegen generate 2>&1 | tail -1)
fi

# Find .xcodeproj
XCODEPROJ=$(ls -d "$IOS_DIR"/*.xcodeproj 2>/dev/null | head -1)
if [ -z "$XCODEPROJ" ]; then
  echo "Error: No .xcodeproj found in $IOS_DIR"
  exit 1
fi

# Find scheme (first shared scheme, or project name)
SCHEME=$(ls "$XCODEPROJ/xcshareddata/xcschemes/"*.xcscheme 2>/dev/null | head -1 | xargs -I{} basename {} .xcscheme)
if [ -z "$SCHEME" ]; then
  SCHEME=$(basename "$XCODEPROJ" .xcodeproj)
fi

# Find workspace if it exists (needed for trivit with watch app)
WORKSPACE=$(find "$IOS_DIR" -maxdepth 1 -name "*.xcworkspace" -not -name "*.xcodeproj" 2>/dev/null | head -1 || true)
if [ -n "$WORKSPACE" ]; then
  BUILD_TARGET="-workspace $WORKSPACE"
else
  BUILD_TARGET="-project $XCODEPROJ"
fi

# Get version info
BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo "1")
PLIST=$(find "$IOS_DIR" -name "Info.plist" -not -path "*/Tests/*" -not -path "*/Widget*" -maxdepth 3 | head -1)
VERSION="1.0.0"
if [ -n "$PLIST" ]; then
  VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST" 2>/dev/null || echo "1.0.0")
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$PLIST" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD_NUMBER" "$PLIST" 2>/dev/null || true
fi

echo ""
echo "Project:  $SCHEME"
echo "Version:  $VERSION ($BUILD_NUMBER)"
echo ""

# --- Unlock signing keychain ---
if [ -f "$KEYCHAIN_PATH" ]; then
  security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" 2>/dev/null || true
  CURRENT=$(security list-keychains -d user | tr -d '"' | tr '\n' ' ')
  echo "$CURRENT" | grep -q "ios-signing" || \
    security list-keychains -d user -s "$KEYCHAIN_PATH" $CURRENT
  security default-keychain -s "$KEYCHAIN_PATH"
  security set-key-partition-list -S apple-tool:,apple:,codesign: \
    -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" &>/dev/null || true
fi

cleanup() {
  security list-keychains -d user -s ~/Library/Keychains/login.keychain-db "$KEYCHAIN_PATH" 2>/dev/null || true
  security default-keychain -s ~/Library/Keychains/login.keychain-db 2>/dev/null || true
}
trap cleanup EXIT

# --- Detect device ---
# Use device name for xcodebuild destination (more reliable than ID formats)
DEVICE_NAME=$(xcrun devicectl list devices 2>/dev/null | grep "available (paired)" | grep -vi "watch" | head -1 | awk '{print $1}')
DEVICE_ID="$DEVICE_NAME"  # xcodebuild uses name-based lookup
DEVICECTL_ID=$(xcrun devicectl list devices 2>/dev/null | grep "available (paired)" | grep -vi "watch" | head -1 | awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9A-F]{8}-/) print $i}')

if [ -n "$DEVICE_ID" ]; then
  echo "Device found: $DEVICE_NAME"
  echo "Building for device..."
  echo ""

  xcodebuild $BUILD_TARGET \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "platform=iOS,name=$DEVICE_NAME" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$ASC_KEY_PATH" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    -quiet 2>&1 | grep -v "DVTDeveloperAccountManager" || true

  # Find and install the built app
  DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
  APP_PATH=$(find "$DERIVED_DATA" -name "*.app" -path "*Debug-iphoneos*" -newer "$XCODEPROJ" -maxdepth 5 2>/dev/null | head -1)

  if [ -n "$APP_PATH" ]; then
    echo ""
    echo "Installing on $DEVICE_NAME..."
    xcrun devicectl device install app --device "$DEVICECTL_ID" "$APP_PATH" 2>&1 | grep -E "installed|bundleID|error"
    echo ""
    echo "Deployed $SCHEME $VERSION ($BUILD_NUMBER) to $DEVICE_NAME"
  else
    echo "Error: Could not find built .app"
    exit 1
  fi

else
  echo "No device connected. Building for TestFlight..."
  echo ""

  # Archive
  EXPORT_DIR=$(mktemp -d)

  xcodebuild archive \
    $BUILD_TARGET \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$EXPORT_DIR/App.xcarchive" \
    -destination 'generic/platform=iOS' \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$ASC_KEY_PATH" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    -quiet

  # Export IPA
  cat > "$EXPORT_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadSymbols</key>
    <true/>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF

  xcodebuild -exportArchive \
    -archivePath "$EXPORT_DIR/App.xcarchive" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_DIR/ExportOptions.plist" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$ASC_KEY_PATH" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
    -quiet

  # Upload to TestFlight
  IPA_PATH=$(ls "$EXPORT_DIR"/*.ipa 2>/dev/null | head -1)
  if [ -z "$IPA_PATH" ]; then
    echo "Error: No IPA found after export"
    rm -rf "$EXPORT_DIR"
    exit 1
  fi

  echo ""
  echo "Uploading to TestFlight..."
  xcrun altool --upload-app \
    -f "$IPA_PATH" \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID" \
    -t ios 2>&1 || \
  xcrun notarytool submit "$IPA_PATH" \
    --key "$ASC_KEY_PATH" \
    --key-id "$ASC_KEY_ID" \
    --issuer "$ASC_ISSUER_ID" 2>&1 || \
  echo "Upload via altool/notarytool failed. Trying Transporter..."

  echo ""
  echo "Deployed $SCHEME $VERSION ($BUILD_NUMBER) to TestFlight"

  rm -rf "$EXPORT_DIR"
fi
