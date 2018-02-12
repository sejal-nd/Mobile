#!/usr/bin/env bash


echo "
Exelon Utilities Mobile Build Script for iOS

Usage:

------- Required Arguments ------

--opco                    - BGE, PECO, or ComEd
--configuration           - Staging, Prodbeta, or Release
--build-number	          - Integer, will be appended to the base version number

------ App Center Arguments -----

Specify these to enable distribution to app center test devices and/or test
groups of users already signed up in App Center

--app-center-api-token    - App center distribution token, create in app center
--app-center-test-devices - Device group ID to deploy for testing. Example: e2d97ee6
--app-center-test-series  - Unused?
--app-center-group        - The app center group to publish signed app to
--app-center-app          - Optional, app center slug. Defaults are set in this script
                            to Exelon-Digital-Projects/EU-Mobile-App-iOS-ProdBeta-$OPCO
------- Optional Arguments ------

The build script already figures these values based on opco + configuration, but if you
need to override the default behavior you can do so with these. However, it's recommended
to just update the build script directly if it's a permanent change.

--bundle-suffix           - Appends to the end of bundle_name.opco if specified
--bundle-name             - Specifies the base bundle_name. Defaults to either:
                            com.exelon.mobile
                            or 
                            com.iphoneproduction.exelon -- if building a ComEd Prod app

--project                 - Name of the xcodeproj -- defaults to Mobile.xcodeproj
--scheme                  - Name of the xcode scheme -- Determined algorithmically

"

PROJECT_DIR="."
ASSET_DIR="$PROJECT_DIR/Mobile/Assets/"
PROJECT="Mobile.xcodeproj"
CONFIGURATION="Release"
UNIT_TEST_SIMULATOR="platform=iOS Simulator,name=iPhone 8,OS=11.2"
BUILD_NUMBER=
BUNDLE_SUFFIX=
BASE_BUNDLE_NAME=
SCHEME=
APP_CENTER_APP=
APP_CENTER_API_TOKEN=
APP_CENTER_TEST_DEVICES=
APP_CENTER_TEST_SERIES="master"
APP_CENTER_GROUP=
OPCO=

# Parse arguments.
for i in "$@"; do
	case $1 in
		--build-number) BUILD_NUMBER="$2"; shift ;;
		--bundle-suffix) BUNDLE_SUFFIX="$2"; shift ;;
		--bundle-name) BASE_BUNDLE_NAME="$2"; shift ;;
		--scheme) SCHEME="$2"; shift ;;
		--project) PROJECT="$2"; shift ;;
		--configuration) CONFIGURATION="$2"; shift ;;
		--app-center-app) APP_CENTER_APP="$2"; shift ;;
		--app-center-api-token) APP_CENTER_API_TOKEN="$2"; shift ;;
		--app-center-test-devices) APP_CENTER_TEST_DEVICES="$2"; shift ;;
		--app-center-test-series) APP_CENTER_TEST_SERIES="$2"; shift ;;
		--app-center-group) APP_CENTER_GROUP="$2"; shift ;;
		--opco) OPCO="$2"; shift ;;
	esac
	shift
done

if [ -z "$BUILD_NUMBER" ]; then
	echo "Missing argument: build-number"
	exit 1
elif [ -z "$CONFIGURATION" ]; then
	echo "Missing argument: configuration"
	exit 1
elif [ -z "$OPCO" ]; then
	echo "Missing argument: opco"
	exit 1
fi

# Project configurations & schemes
#   Develop - DEVELOP
#   Automation - AUT & AUT-UITest
#   Staging - STAGING
#   Release - PROD
#   Prodbeta - PRODBETA


current_icon_set="${ASSET_DIR}${OPCO}Assets.xcassets/AppIcon.appiconset"

target_bundle_id=
target_app_name=
target_icon_asset=
target_scheme=
target_app_center_app=

OPCO_LOWERCASE=$(echo "$OPCO" | tr '[:upper:]' '[:lower:]')

if [ -z "$BASE_BUNDLE_NAME" ]; then
	BASE_BUNDLE_NAME="com.exelon.mobile.$OPCO_LOWERCASE"
fi

if [ "$CONFIGURATION" == "Staging" ]; then
	target_bundle_id="$BASE_BUNDLE_NAME.staging"
	target_app_name="$OPCO Staging"
	target_icon_asset="tools/$OPCO/staging"
	target_scheme="$OPCO-STAGING"
	target_app_center_app="Exelon-Digital-Projects/EU-Mobile-App-iOS-Stage-$OPCO"

elif [ "$CONFIGURATION" == "Prodbeta" ]; then
	target_bundle_id="$BASE_BUNDLE_NAME.prodbeta"
	target_app_name="$OPCO Prodbeta"
	target_icon_asset="tools/$OPCO/prodbeta"
	target_scheme="$OPCO-PRODBETA"
	target_app_center_app="Exelon-Digital-Projects/EU-Mobile-App-iOS-ProdBeta-$OPCO"
elif [ "$CONFIGURATION" == "Release" ]; then
	if [ "$OPCO_LOWERCASE" == "comed" ]; then
		# ComEd's production app bundle is different because of the previous Kony mobile app
		target_bundle_id="com.iphoneproduction.exelon"
	else
		target_bundle_id="$BASE_BUNDLE_NAME"
	fi
	target_app_name="$OPCO"
	target_icon_asset="tools/$OPCO/release"
	target_scheme="$OPCO-PROD"
	target_app_center_app="Exelon-Digital-Projects/EU-Mobile-App-iOS-Prod-$OPCO"
else
	echo "Invalid argument: configuration"
	echo "    value must be either \"Staging\", \"Prodbeta\", or \"Release\""
	exit 1
fi

if [ -n "$SCHEME" ]; then
	echo "Scheme has been specified via args -- overriding default of $target_scheme with $SCHEME"
	target_scheme=$SCHEME
fi

if [ -n "$APP_CENTER_APP" ]; then
	echo "App center app has been specified via args -- overriding default of $target_app_center_app with $APP_CENTER_APP"
	target_app_name=$APP_CENTER_APP
fi


echo "Replacing app icon set..."
subs=`ls $target_icon_asset`

for i in $subs; do
	if [[ $i == *.png ]]; then
		echo "    Updating: $i"
		rm -rf "$current_icon_set/$i"
		cp "$target_icon_asset/$i" "$current_icon_set"
	fi
done
echo "App Icon updated:"
echo "   Replaced current_icon_set=$current_icon_set"
echo "   with: "
echo "   AppIconSet=$target_icon_asset"

echo "Updating plist $PROJECT_DIR/Mobile/$OPCO-Info.plist"

# Update Bundle ID, App Name, App Version, and Icons
plutil -replace CFBundleVersion -string $BUILD_NUMBER $PROJECT_DIR/Mobile/$OPCO-Info.plist
plutil -replace CFBundleName -string "$target_app_name" $PROJECT_DIR/Mobile/$OPCO-Info.plist

echo "$PROJECT_DIR/Mobile/$OPCO-Info.plist updated:"
echo "   CFBundleVersion=$BUILD_NUMBER"
if [ -n "$BUNDLE_SUFFIX" ]; then 
	# Optional -- the defaults are all defined in the xcode project, this just gives the user the ability to override
	echo "   CFBundleIdentifier=$target_bundle_id"
	plutil -replace CFBundleIdentifier -string $target_bundle_id $PROJECT_DIR/Mobile/$OPCO-Info.plist
else
	echo "   CFBundleIdentifier=(Left as is -- should be \${EXM_BUNDLE_ID} which means Xcode project settings take affect)"
fi
echo "   CFBundleName=$target_app_name"
echo ""


# Restore Carthage Packages

# carthage update --platform iOS --project-directory $PROJECT_DIR
carthage update --platform iOS --project-directory $PROJECT_DIR --cache-builds

# Run Unit Tests

echo "Running automation tests"
xcrun xcodebuild  -sdk iphonesimulator \
	-project $PROJECT \
	-scheme "$OPCO-AUT" \
	-destination "$UNIT_TEST_SIMULATOR" \
	-configuration Automation \
	test | xcpretty --report junit


echo "------------------------------ Building Application  ----------------------------"
# Build App

xcrun xcodebuild -sdk iphoneos \
	-configuration $CONFIGURATION \
	-project $PROJECT \
	-scheme "$target_scheme" \
	-archivePath build/archive/$target_scheme.xcarchive \
	archive

echo "--------------------------------- Post archiving  -------------------------------"


# # Archive App
xcrun xcodebuild \
	-exportArchive \
	-archivePath build/archive/$target_scheme.xcarchive \
	-exportPath build/output/$target_scheme \
	-exportOptionsPlist tools/ExportPlists/$target_scheme.plist

echo "--------------------------------- Post exporting -------------------------------"

# Push to App Center Test

if  [ -n "$APP_CENTER_API_TOKEN" ] && [ -n "$APP_CENTER_TEST_DEVICES" ]; then

	# rm -rf "DerivedData"
	echo "----------------------------------- Build-for-testing -------------------------------"
	xcrun xcodebuild \
		-configuration Automation \
		-project $PROJECT \
		-sdk iphoneos \
		-scheme "$OPCO-AUT-UITest" \
		build-for-testing 

	
	echo "--------------------------------- Uploading to appcenter -------------------------------"
	# Upload your test to App Center
	appcenter test run xcuitest \
		--app $target_app_center_app \
		--devices $APP_CENTER_TEST_DEVICES \
		--test-series "$APP_CENTER_TEST_SERIES"  \
		--locale "en_US" \
		--build-dir Build/Automation \
		--token $APP_CENTER_API_TOKEN \
		--async

else
	echo "Skipping App Center Test due to missing variables - \"app-center-test-devices\", or \"app-center-api-token\""
fi

# Push to App Center Distribute
if [ -n "$APP_CENTER_GROUP" ] && [ -n "$APP_CENTER_API_TOKEN" ]; then

	 # echo "test"
	appcenter distribute release \
		--app $target_app_center_app \
		--token $APP_CENTER_API_TOKEN \
		--file build/output/$target_scheme/$target_scheme.ipa \
		--group $APP_CENTER_GROUP

else
	echo "Skipping App Center Distribution due to missing variables - \"app-center-group\" or \"app-center-api-token\""
fi