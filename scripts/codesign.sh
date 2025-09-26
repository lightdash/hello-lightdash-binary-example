#!/bin/bash

# Load environment variables (fallback to defaults if not set)
DEVELOPER_ID="${DEVELOPER_ID:-AF5SF5H727}"
BUNDLE_ID="${BUNDLE_ID:-com.lightdash.hello}"
ENTITLEMENTS="entitlements.plist"

echo "Signing binaries with Developer ID: $DEVELOPER_ID"
echo "Bundle ID: $BUNDLE_ID"
echo ""

# Make binaries executable
echo "Making binaries executable..."
chmod +x "bin/hello-lightdash-x64"
chmod +x "bin/hello-lightdash-arm64"

# Sign x64 binary
echo "Signing hello-lightdash-x64..."
codesign -s "$DEVELOPER_ID" -f --timestamp -o runtime -i "$BUNDLE_ID" --entitlements "$ENTITLEMENTS" "bin/hello-lightdash-x64"

# Sign ARM64 binary
echo "Signing hello-lightdash-arm64..."
codesign -s "$DEVELOPER_ID" -f --timestamp -o runtime -i "$BUNDLE_ID" --entitlements "$ENTITLEMENTS" "bin/hello-lightdash-arm64"

echo ""
echo "Verifying signatures..."
echo ""

# Verify x64 binary
echo "Verifying hello-lightdash-x64:"
codesign --verify --verbose "bin/hello-lightdash-x64"

# Verify ARM64 binary
echo "Verifying hello-lightdash-arm64:"
codesign --verify --verbose "bin/hello-lightdash-arm64"

echo ""
echo "Done!"