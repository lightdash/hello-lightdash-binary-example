#!/bin/bash

# Load environment variables (fallback to defaults if not set)
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-AppPasswordCodesignNotarize}"
BUNDLE_ID="${BUNDLE_ID:-com.lightdash.hello}"

echo "Notarizing binaries using keychain profile: $KEYCHAIN_PROFILE"
echo ""

# Create a temporary directory for zip files
TEMP_DIR="bin/notarize-temp"
mkdir -p "$TEMP_DIR"

# Function to notarize a binary
notarize_binary() {
    local BINARY_NAME=$1
    local BINARY_PATH="bin/$BINARY_NAME"
    local ZIP_PATH="$TEMP_DIR/$BINARY_NAME.zip"

    echo "Processing $BINARY_NAME..."
    echo "  Creating zip for notarization..."

    # Create a zip file for notarization (Apple requires zip format)
    ditto -c -k --keepParent "$BINARY_PATH" "$ZIP_PATH"

    echo "  Submitting for notarization..."

    # Submit for notarization and wait for result
    xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait

    if [ $? -eq 0 ]; then
        echo "  ✓ Notarization successful"
        echo "  Note: Standalone binaries cannot be stapled directly."
        echo "        They will be verified online on first run."
    else
        echo "  ✗ Notarization failed"
    fi

    echo ""
}

# Notarize both binaries
notarize_binary "hello-lightdash-x64"
notarize_binary "hello-lightdash-arm64"

# Check notarization status
echo "Checking notarization status..."
echo ""

echo "hello-lightdash-x64:"
xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" | grep hello-lightdash-x64 | head -1

echo "hello-lightdash-arm64:"
xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" | grep hello-lightdash-arm64 | head -1

# Clean up temporary files
echo ""
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo ""
echo "Done! Binaries are notarized."
echo ""
echo "Note: Standalone executables cannot have tickets stapled directly."
echo "      They will be verified online when first run."
echo ""
echo "For offline verification, distribute in a notarized DMG or ZIP."