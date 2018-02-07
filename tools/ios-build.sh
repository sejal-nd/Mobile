#!/usr/bin/env bash

PROJECT_DIR="./"
ASSET_DIR="$PROJECT_DIR/Mobile/Assets/"
INFO_PLIST=""
APP_PLIST=""
WORKSPACE=""
CONFIGURATION="Release"
UNIT_TEST_SIMULATOR="platform=iOS Simulator,name=iPhone 8,OS=11.2"

BUILD_NUMBER=
BUNDLE_SUFFIX=
BASE_BUNDLE_NAME=
BASE_APP_NAME=
SCHEME=
WORKSPACE=
APP_CENTER_APP=
APP_CENTER_API_TOKEN=
APP_CENTER_TEST_DEVICES=
APP_CENTER_TEST_SERIES="master"
OPCO=

# Parse arguments.
for i in "$@"; do
    case $1 in
        --build-number) BUILD_NUMBER="$2"; shift ;;
        --bundle-suffix) BUNDLE_SUFFIX="$2"; shift ;;
        --bundle-name) BASE_BUNDLE_NAME="$2"; shift ;;
        --app-name) BASE_APP_NAME="$2"; shift ;;
        --scheme) SCHEME="$2"; shift ;;
        --workspace) WORKSPACE="$2"; shift ;;
        --configuration) CONFIGURATION="$2"; shift ;;
        --app-center-app) APP_CENTER_APP="$2"; shift ;;
        --app-center-api-token) APP_CENTER_API_TOKEN="$2"; shift ;;
        --app-center-test-devices) APP_CENTER_TEST_DEVICES="$2"; shift ;;
        --app-center-test-series) APP_CENTER_TEST_SERIES="$2"; shift ;;
        --opco) OPCO="$2"; shift ;;
    esac
    shift
done

if [ -z "$BUILD_NUMBER" ]; then
      echo "Missing argument: build-number"
      exit 1
elif [ -z "$BUNDLE_SUFFIX" ]; then
      echo "Missing argument: bundle-suffix"
      exit 1
elif [ -z "$BASE_BUNDLE_NAME" ]; then
      echo "Missing argument: bundle-name"
      exit 1
elif [ -z "$BASE_APP_NAME" ]; then
      echo "Missing argument: app-name"
      exit 1
elif [ -z "$SCHEME" ]; then
      echo "Missing argument: scheme"
      exit 1
elif [ -z "$WORKSPACE" ]; then
      echo "Missing argument: workspace"
      exit 1
elif [ -z "$OPCO" ]; then
      echo "Missing argument: opco"
      exit 1
fi

current_icon_set = "${ASSET_DIR}${OPCO}Assets.xcassets/AppIcon.appiconset"

target_bundle_id=
target_app_name=
target_icon_asset=

if [ "$BUNDLE_SUFFIX" == "staging" ]; then
    target_bundle_id="$BASE_BUNDLE_NAME-staging"
    target_app_name="$BASE_APP_NAME-Staging"
    target_icon_asset="tools/$OPCO/$BUNDLE_SUFFIX/AppIcon.appiconset"
elif [ "$BUNDLE_SUFFIX" == "prodbeta" ]; then
    target_bundle_id="$BASE_BUNDLE_NAME-prodbeta"
    target_app_name="$BASE_APP_NAME-Prodbeta"
    target_icon_asset="tools/$OPCO/$BUNDLE_SUFFIX/AppIcon.appiconset"
elif [ "$BUNDLE_SUFFIX" == "release" ]; then
    target_bundle_id="$BASE_BUNDLE_NAME"
    target_app_name="$BASE_APP_NAME"
    target_icon_asset="tools/$OPCO/$BUNDLE_SUFFIX/AppIcon.appiconset"
fi

if [ -z "$target_bundle_id" ] || [ -z "$target_app_name" ] || [ -z "$target_icon_asset" ]; then
      echo "Invalid argument: bundleSuffix"
      echo "    value must be either \"staging\", \"prodbeta\", or \"release\""
      exit 1
fi

# Update Bundle ID, App Name, App Version, and Icons

plutil -replace CFBundleVersion -string $BUILD_NUMBER $PROJECT_DIR/Mobile/$OPCO-Info.plist
plutil -replace CFBundleIdentifier -string $target_bundle_id $PROJECT_DIR/Mobile/$OPCO-Info.plist
plutil -replace CFBundleName -string $target_app_name $PROJECT_DIR/Mobile/$OPCO-Info.plist

rm -rf "$current_icon_set"
cp -r "$target_icon_asset" "$current_icon_set"

echo "Info.plist updated:"
echo "   CFBundleVersion=$BUILD_NUMBER"
echo "   CFBundleIdentifier=$target_bundle_id"
echo "   CFBundleName=$target_app_name"
echo ""
echo "App Icon updated:"
echo "   AppIconSet=$target_icon_asset"

# Restore Carthage Packages

carthage update --platform iOS --project-directory $PROJECT_DIR

# Run Unit Tests

xcrun xcodebuild  -sdk iphonesimulator \
  -workspace $WORKSPACE \
  -scheme $SCHEME \
  -destination $UNIT_TEST_SIMULATOR \
  test

# Build App

xcrun xcodebuild -sdk iphoneos \
    -configuration $CONFIGURATION \
    -workspace $WORKSPACE \
    -scheme $SCHEME \
    -archivePath BUILD \
    build

# Push to App Center Test

if [ -n "$APP_CENTER_APP" ] && [ -n "$APP_CENTER_API_TOKEN" ] && [ -n "$APP_CENTER_TEST_DEVICES" ]; then

    rm -rf "DerivedData"
    xcrun xcodebuild build-for-testing \
        -configuration Debug \
        -workspace $WORKSPACE \
        -sdk iphoneos \
        -scheme $SCHEME-UITest \
        -derivedDataPath DerivedData

    # Upload your test to App Center
    appcenter test run xcuitest \
        --app $APP_CENTER_APP \
        --devices $APP_CENTER_TEST_DEVICES \
        --test-series "$APP_CENTER_TEST_SERIES"  \
        --locale "en_US" \
        --build-dir DerivedData/Build/Products/Debug-iphoneos \
        --token $APP_CENTER_API_TOKEN \
        --async

else
    echo "Skipping App Center Test due to missing variables - \"app-center-app\", \"app-center-test-devices\", or \"app-center-api-token\""
fi

# Push to App Center Distribute
if [ -n "$APP_CENTER_APP" ] && [ -n "$APP_CENTER_API_TOKEN" ]; then

    appcenter distribute release \
        --app $APP_CENTER_APP \
        --token $APP_CENTER_API_TOKEN
        --file Build/Products/$CONFIGURATION-iphoneos/*.ipa

else
    echo "Skipping App Center Distribution due to missing variables - \"app-center-app\" or \"app-center-api-token\""
fi