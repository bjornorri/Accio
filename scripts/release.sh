#!/bin/bash

# MacOS App Release Script
# This script builds, signs, notarizes, and creates a GitHub release for your macOS app

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Project root is one level up from scripts/ directory
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ============================================================================
# CONFIGURATION - Update these values for your project
# ============================================================================

# Your app and project details
APP_NAME="Accio"  # Name of your .app (without .app extension)
XCODE_PROJECT="$PROJECT_ROOT/Accio.xcodeproj"  # or Accio.xcworkspace if you use CocoaPods/SPM workspace
SCHEME_NAME="Accio"  # Your Xcode scheme name
BUNDLE_ID="com.bjornorri.Accio"  # Your bundle identifier

# Signing and notarization
DEVELOPER_ID="Developer ID Application: Bjorn Orri Saemundsson (5762VEA4LK)"
KEYCHAIN_PROFILE="accio-notary"  # Name of your stored notarytool profile

# GitHub details
GITHUB_REPO="bjornorri/Accio"

# Build configuration
BUILD_CONFIG="Release"
ARCHIVE_PATH="$PROJECT_ROOT/build/archive.xcarchive"
EXPORT_PATH="$PROJECT_ROOT/build/export"
DMG_PATH="$PROJECT_ROOT/build"

# ============================================================================
# FUNCTIONS
# ============================================================================

print_step() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
}

check_requirements() {
    print_step "Checking requirements"

    # Check for required tools
    command -v xcodebuild >/dev/null 2>&1 || { echo "Error: xcodebuild not found"; exit 1; }
    command -v gh >/dev/null 2>&1 || { echo "Error: GitHub CLI (gh) not found. Install with: brew install gh"; exit 1; }
    command -v git >/dev/null 2>&1 || { echo "Error: git not found"; exit 1; }
    command -v create-dmg >/dev/null 2>&1 || { echo "Error: create-dmg not found. Install with: brew install create-dmg"; exit 1; }

    # Check GitHub CLI authentication
    if ! gh auth status >/dev/null 2>&1; then
        echo "Error: Not authenticated with GitHub CLI"
        echo "Please run: gh auth login"
        exit 1
    fi

    # Check for notarytool profile
    if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" >/dev/null 2>&1; then
        echo "Error: Notarytool profile '$KEYCHAIN_PROFILE' not found"
        echo "Please store your credentials first:"
        echo "  xcrun notarytool store-credentials $KEYCHAIN_PROFILE --apple-id <your-email> --team-id <team-id>"
        exit 1
    fi

    # Check if we're in a git repository (check project root)
    if ! git -C "$PROJECT_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Project root is not a git repository: $PROJECT_ROOT"
        exit 1
    fi

    # Check for clean git tree
    if [ -n "$(git -C "$PROJECT_ROOT" status --porcelain)" ]; then
        echo "Error: Git working directory is not clean"
        echo ""
        echo "You have uncommitted changes:"
        git -C "$PROJECT_ROOT" status --short
        echo ""
        echo "Please commit or stash your changes before creating a release."
        exit 1
    fi

    # Check if we're on a branch (not detached HEAD)
    if ! git -C "$PROJECT_ROOT" symbolic-ref -q HEAD >/dev/null; then
        echo "Error: Detached HEAD state detected"
        echo "Please checkout a branch before creating a release."
        exit 1
    fi

    # Check if current branch has an upstream
    CURRENT_BRANCH=$(git -C "$PROJECT_ROOT" symbolic-ref --short HEAD)
    if git -C "$PROJECT_ROOT" rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
        # Fetch latest from remote to compare
        echo "Checking if branch is up to date with remote..."
        git -C "$PROJECT_ROOT" fetch origin "$CURRENT_BRANCH" 2>/dev/null || git -C "$PROJECT_ROOT" fetch 2>/dev/null || true

        LOCAL=$(git -C "$PROJECT_ROOT" rev-parse @)
        REMOTE=$(git -C "$PROJECT_ROOT" rev-parse @{u} 2>/dev/null || echo "")
        BASE=$(git -C "$PROJECT_ROOT" merge-base @ @{u} 2>/dev/null || echo "")

        if [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
            if [ "$LOCAL" = "$BASE" ]; then
                echo "Warning: Your branch is behind the remote. Consider pulling first."
                read -p "Continue anyway? (y/n) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    exit 1
                fi
            elif [ "$REMOTE" = "$BASE" ]; then
                echo "Warning: You have unpushed commits."
                read -p "Continue anyway? (y/n) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    exit 1
                fi
            else
                echo "Error: Your branch has diverged from the remote."
                echo "Please sync with remote before creating a release."
                exit 1
            fi
        fi
    fi

    echo "✓ All requirements met"
}

get_version_from_xcode() {
    print_step "Extracting version from Xcode project"

    # Verify the Xcode project exists
    if [ ! -f "$XCODE_PROJECT/project.pbxproj" ] && [ ! -d "${XCODE_PROJECT%.xcodeproj}.xcworkspace" ]; then
        echo "Error: Could not find Xcode project at $XCODE_PROJECT"
        echo "Project root: $PROJECT_ROOT"
        exit 1
    fi

    # Try to get version from Info.plist in the project
    if [ -f "$XCODE_PROJECT/project.pbxproj" ]; then
        # Get the Info.plist path from the project
        PLIST_PATH=$(find "$PROJECT_ROOT" -name "Info.plist" -path "*/$APP_NAME/*" | head -1)

        if [ -f "$PLIST_PATH" ]; then
            VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PLIST_PATH" 2>/dev/null || echo "")
            BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST_PATH" 2>/dev/null || echo "")
        fi
    fi

    # Fallback: try to extract from xcodebuild
    if [ -z "$VERSION" ]; then
        VERSION=$(xcodebuild -project "$XCODE_PROJECT" -scheme "$SCHEME_NAME" -showBuildSettings | grep "MARKETING_VERSION" | awk '{print $3}' | head -1)
        BUILD=$(xcodebuild -project "$XCODE_PROJECT" -scheme "$SCHEME_NAME" -showBuildSettings | grep "CURRENT_PROJECT_VERSION" | awk '{print $3}' | head -1)
    fi

    if [ -z "$VERSION" ]; then
        echo "Error: Could not determine version from Xcode project"
        exit 1
    fi

    if [ -z "$BUILD" ]; then
        BUILD="1"
    fi

    FULL_VERSION="${VERSION}"

    echo "✓ Version: $FULL_VERSION (Build: $BUILD)"
}

clean_build() {
    print_step "Cleaning previous builds"
    rm -rf "$PROJECT_ROOT/build"
    mkdir -p "$PROJECT_ROOT/build"
    echo "✓ Build directory cleaned"
}

build_app() {
    print_step "Building app"

    # Determine if using workspace or project
    if [ -f "${XCODE_PROJECT%.xcodeproj}.xcworkspace" ]; then
        PROJECT_ARG="-workspace ${XCODE_PROJECT%.xcodeproj}.xcworkspace"
    else
        PROJECT_ARG="-project $XCODE_PROJECT"
    fi

    # Build without code signing (we'll sign manually)
    xcodebuild archive \
        $PROJECT_ARG \
        -scheme "$SCHEME_NAME" \
        -configuration "$BUILD_CONFIG" \
        -archivePath "$ARCHIVE_PATH" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        | xcpretty || xcodebuild archive \
        $PROJECT_ARG \
        -scheme "$SCHEME_NAME" \
        -configuration "$BUILD_CONFIG" \
        -archivePath "$ARCHIVE_PATH" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO

    echo "✓ App built successfully"
}

sign_app() {
    print_step "Signing app"

    APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"

    # Sign all frameworks and nested binaries first
    find "$APP_PATH/Contents" -type f \( -name "*.dylib" -o -name "*.framework" \) -print0 | while IFS= read -r -d '' file; do
        codesign --force --sign "$DEVELOPER_ID" --timestamp --options runtime "$file" 2>/dev/null || true
    done

    # Sign the main app bundle
    codesign --force --sign "$DEVELOPER_ID" \
        --timestamp \
        --options runtime \
        --entitlements "$APP_PATH/Contents/Resources/$APP_NAME.entitlements" \
        --deep \
        "$APP_PATH" 2>/dev/null || \
    codesign --force --sign "$DEVELOPER_ID" \
        --timestamp \
        --options runtime \
        --deep \
        "$APP_PATH"

    # Verify the signature
    codesign --verify --deep --strict --verbose=2 "$APP_PATH"

    echo "✓ App signed successfully"
}

export_app() {
    print_step "Exporting app"

    # Create export directory and copy the signed app
    mkdir -p "$EXPORT_PATH"
    cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME.app" "$EXPORT_PATH/"

    echo "✓ App exported successfully"
}

notarize_app() {
    print_step "Notarizing app"

    APP_PATH="$EXPORT_PATH/$APP_NAME.app"
    ZIP_PATH="./build/$APP_NAME-$FULL_VERSION.zip"

    # Create zip for notarization
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

    echo "Submitting for notarization..."
    xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait

    # Staple the notarization ticket
    echo "Stapling notarization ticket..."
    xcrun stapler staple "$APP_PATH"

    echo "✓ App notarized and stapled successfully"
}

create_dmg() {
    print_step "Creating DMG"

    APP_PATH="$EXPORT_PATH/$APP_NAME.app"
    DMG_NAME="$APP_NAME-$FULL_VERSION.dmg"
    DMG_FILE="$DMG_PATH/$DMG_NAME"

    if command -v create-dmg >/dev/null 2>&1; then
        # Use create-dmg for a professional-looking DMG
        create-dmg \
            --volname "$APP_NAME" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon "$APP_NAME.app" 175 190 \
            --hide-extension "$APP_NAME.app" \
            --app-drop-link 425 190 \
            --no-internet-enable \
            "$DMG_FILE" \
            "$APP_PATH"

        # create-dmg returns non-zero even on success sometimes, so we check if file exists
        if [ ! -f "$DMG_FILE" ]; then
            echo "Error: DMG creation failed"
            exit 1
        fi
    else
        echo "Error: create-dmg not found. Install with: brew install create-dmg"
        exit 1
    fi

    echo "✓ DMG created: $DMG_FILE"

    # Sign the DMG
    echo "Signing DMG..."
    codesign --sign "$DEVELOPER_ID" --timestamp "$DMG_FILE"

    # Notarize the DMG
    echo "Notarizing DMG..."
    xcrun notarytool submit "$DMG_FILE" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait

    # Staple the DMG
    echo "Stapling notarization ticket to DMG..."
    xcrun stapler staple "$DMG_FILE"

    echo "✓ DMG created, signed, and notarized: $DMG_FILE"
}

create_zip() {
    print_step "Creating ZIP distribution"

    APP_PATH="$EXPORT_PATH/$APP_NAME.app"
    ZIP_NAME="$APP_NAME-$FULL_VERSION.zip"
    ZIP_FILE="$DMG_PATH/$ZIP_NAME"

    # Create ZIP (preserving code signatures and extended attributes)
    ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_FILE"

    echo "✓ ZIP created: $ZIP_FILE"
}

create_github_release() {
    print_step "Creating GitHub release"

    TAG_NAME="v$FULL_VERSION"
    DMG_NAME="$APP_NAME-$FULL_VERSION.dmg"
    DMG_FILE="$DMG_PATH/$DMG_NAME"
    ZIP_NAME="$APP_NAME-$FULL_VERSION.zip"
    ZIP_FILE="$DMG_PATH/$ZIP_NAME"

    # Check if tag exists
    if git -C "$PROJECT_ROOT" rev-parse "$TAG_NAME" >/dev/null 2>&1; then
        echo "Warning: Tag $TAG_NAME already exists"
        read -p "Do you want to delete and recreate it? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git -C "$PROJECT_ROOT" tag -d "$TAG_NAME"
            git -C "$PROJECT_ROOT" push origin ":refs/tags/$TAG_NAME" 2>/dev/null || true
        else
            echo "Aborting release creation"
            exit 1
        fi
    fi

    # Create and push tag
    git -C "$PROJECT_ROOT" tag -a "$TAG_NAME" -m "Release $FULL_VERSION"
    git -C "$PROJECT_ROOT" push origin "$TAG_NAME"

    # Minimal release notes template
    RELEASE_NOTES="## Release Notes

"

    # Create GitHub release with tag name as title and minimal template
    gh release create "$TAG_NAME" \
        --repo "$GITHUB_REPO" \
        --title "$TAG_NAME" \
        --notes "$RELEASE_NOTES" \
        "$DMG_FILE" \
        "$ZIP_FILE"

    echo "✓ GitHub release created: https://github.com/$GITHUB_REPO/releases/tag/$TAG_NAME"
    echo "  Edit the release notes on GitHub to add details"
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

main() {
    echo "🚀 Starting release process for Accio"
    echo "Project root: $PROJECT_ROOT"
    echo ""

    check_requirements
    get_version_from_xcode
    clean_build
    build_app
    sign_app
    export_app
    notarize_app
    create_dmg
    create_zip
    create_github_release

    print_step "✅ Release complete!"
    echo "Version $FULL_VERSION has been released to GitHub"
}

# Run main function
main
