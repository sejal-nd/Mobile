#!/usr/bin/env bash


# Reads in the mobile cloud config file directly, filtering out prod instances
# Have to convert to json first

plutil -convert json -e json App/MCSConfig.plist

string_of_mbes="$(jq -r '.mobileBackends|keys[]' < App/Supporting\ Files/MCSConfig.json | grep -v Prod)"

stagingMBEs=($string_of_mbes)

rm App/Supporting\ Files/MCSConfig.json

echo "
Exelon Utilities Mobile Build Script for iOS

Usage:

------- Required Arguments ------

--opco                    - BGE, PECO, or ComEd, ACE, Pepco, Delmarva
--build-number            - Integer, will be appended to the base version number

--configuration           - Testing, Staging, Prodbeta, Hotfix, or Release

                            or

--build-branch              refs/heads/develop
                            refs/heads/test
                            refs/heads/stage
                            refs/heads/prodbeta
                            refs/heads/hotfix
                            refs/heads/master
                            refs/heads/phi/develop
                            refs/heads/phi/stage

------ App Center Arguments -----

Specify these to enable distribution to app center test devices and/or test
groups of users already signed up in App Center

--app-center-api-token    - App center distribution token, create in app center
--app-center-test-devices - Device group ID to deploy for testing. Example: e2d97ee6
--app-center-test-series  - Unused?
--app-center-group        - The app center group to publish signed app to
--app-center-app          - Optional, app center slug. Defaults are set in this script
                            to Exelon-Digital-Projects/EU-Mobile-App-iOS-ProdBeta-\$OPCO
------- Optional Arguments ------

The build script already figures these values based on opco + configuration, but if you
need to override the default behavior you can do so with these. However, it's recommended
to just update the build script directly if it's a permanent change.

--nowsecure-api-token     - API key for NowSecure security scanning system
--azuredevopstoken        - A token used by the eucoms-list-changes.sh script to access pull
                            request and work item details to generate release notes.
                            See the EU-DevOps -> eucoms-list-changes repo for details
--releasenotesprnumber    - The pull request number to generate release notes off of
--releasenotescontent     - Alternative, a quick blurb to upload for release notes
--project                 - Name of the xcworkspace -- defaults to Mobile.xcworkspace
--scheme                  - Name of the xcode scheme -- Determined algorithmically
--phase                   - cocoapods, build, nowsecure, unitTest, appCenterTest, appCenterSymbols, distribute, writeDistributionScript
--override-mbe            - Override the default MBE for testing or staging builds only
                          - Options: ${stagingMBEs[*]}
"

PROPERTIES_FILE='version.properties'
PROJECT_DIR="."
ASSET_DIR="$PROJECT_DIR/App/Resources/"
PROJECT="Mobile.xcworkspace"
CONFIGURATION=""
UNIT_TEST_SIMULATOR="platform=iOS Simulator,name=iPhone 8"
BUILD_NUMBER=
SCHEME=
APP_CENTER_APP=
APP_CENTER_API_TOKEN=
APP_CENTER_TEST_DEVICES=
APP_CENTER_TEST_SERIES="master"
APP_CENTER_GROUP=
OPCO=
PHASE=
BUILD_BRANCH=
OVERRIDE_MBE=
AZURE_DEVOPS_TOKEN=
RELEASE_NOTES_PR_NUMBER=
RELEASE_NOTES_CONTENT=
NOWSECURE_API_TOKEN=

# Parse arguments.
for i in "$@"; do
    case $1 in
        --build-number) BUILD_NUMBER="$2"; shift ;;
        --scheme) SCHEME="$2"; shift ;;
        --project) PROJECT="$2"; shift ;;
        --configuration) CONFIGURATION="$2"; shift ;;
        --app-center-app) APP_CENTER_APP="$2"; shift ;;
        --app-center-api-token) APP_CENTER_API_TOKEN="$2"; shift ;;
        --app-center-test-devices) APP_CENTER_TEST_DEVICES="$2"; shift ;;
        --app-center-test-series) APP_CENTER_TEST_SERIES="$2"; shift ;;
        --app-center-group) APP_CENTER_GROUP="$2"; shift ;;
        --opco) OPCO="$2"; shift ;;
        --phase) PHASE="$2"; shift ;;
        --build-branch) BUILD_BRANCH="$2"; shift ;;
        --override-mbe) OVERRIDE_MBE="$2"; shift ;;
        --azuredevopstoken) AZURE_DEVOPS_TOKEN="$2"; shift ;;
        --releasenotesprnumber) RELEASE_NOTES_PR_NUMBER="$2"; shift ;;
        --releasenotescontent) RELEASE_NOTES_CONTENT="$2"; shift ;;
        --nowsecure-api-token) NOWSECURE_API_TOKEN="$2"; shift ;;
    esac
    shift
done

check_errs()
{
  # Function. Parameter 1 is the return code
  # Para. 2 is text to display on failure.
  if [ "${1}" -ne "0" ]; then
    echo "ERROR # ${1} : ${2}"
    # as a bonus, make our script exit with the right error code.
    exit ${1}
  fi
}

# https://stackoverflow.com/questions/3685970/check-if-a-bash-array-contains-a-value
find_in_array() {
  local word=$1
  shift
  for e in "$@"; do
    [[ "$e" == "$word" ]] && return 0;
  done
}

mkdir -p build/logs

# git repo branches can be used to specify the build type instead of the configuration directly
if [[ "$BUILD_BRANCH" == "refs/heads/develop" ]]; then
  # Supports CI builds for all builds into the dev branch
  CONFIGURATION="Testing"
elif [[ "$BUILD_BRANCH" == "refs/heads/phi/develop" ]]; then
  CONFIGURATION="Testing"
elif [[ "$BUILD_BRANCH" == "refs/heads/test" ]]; then
  CONFIGURATION="Testing"
elif [[ "$BUILD_BRANCH" == "refs/heads/stage" ]]; then
  CONFIGURATION="Staging"
elif [[ "$BUILD_BRANCH" == "refs/heads/phi/stage" ]]; then
  CONFIGURATION="Staging"
elif [[ "$BUILD_BRANCH" == "refs/heads/prodbeta" ]]; then
  CONFIGURATION="Prodbeta"
elif [[ "$BUILD_BRANCH" == "refs/heads/hotfix" ]]; then
  CONFIGURATION="Hotfix"
elif [[ "$BUILD_BRANCH" == "refs/heads/master" ]]; then
  CONFIGURATION="Release"
fi

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

target_phases="cocoapods, build, nowsecure, unitTest, appCenterTest, appCenterSymbols, distribute, writeDistributionScript"

if [ -n "$PHASE" ]; then
  target_phases="$PHASE"
fi


if [ -f "$PROPERTIES_FILE" ]; then
  echo "$PROPERTIES_FILE found."

  while IFS='=' read -r key value
  do
    key=$(echo $key | tr '.' '_')
    eval "${key}='${value}'"
  done < "$PROPERTIES_FILE"
else
  echo "$PROPERTIES_FILE not found."
fi

echo "Executing the following phases: $target_phases"

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
target_version_number=

OPCO_LOWERCASE=$(echo "$OPCO" | tr '[:upper:]' '[:lower:]')

if [ "$OPCO" == "BGE" ]; then
    target_version_number=$BGE_VERSION_NUMBER
elif [ "$OPCO" == "ComEd" ]; then
    target_version_number=$COMED_VERSION_NUMBER
elif [ "$OPCO" == "PECO" ]; then
    target_version_number=$PECO_VERSION_NUMBER
elif [ "$OPCO" == "Pepco" ]; then
    target_version_number=$PEPCO_VERSION_NUMBER
elif [ "$OPCO" == "Delmarva" ]; then
    target_version_number=$DELMARVA_VERSION_NUMBER
elif [ "$OPCO" == "ACE" ]; then
    target_version_number=$ACE_VERSION_NUMBER
fi

if [ "$CONFIGURATION" == "Testing" ]; then
    target_app_name="$OPCO Testing"
    target_icon_asset="tools/$OPCO/testing"
    target_scheme="$OPCO-TESTING"
    target_app_center_app="Exelon-Digital-Projects/EU-Mobile-App-iOS-Test-$OPCO"
    target_version_number="$target_version_number.$BUILD_NUMBER-testing"
elif [ "$CONFIGURATION" == "Staging" ]; then
    target_app_name="$OPCO Staging"
    target_icon_asset="tools/$OPCO/staging"
    target_scheme="$OPCO-STAGING"
    target_app_center_app="Exelon-Digital-Projects/EU-Mobile-App-iOS-Stage-$OPCO"
    target_version_number="$target_version_number.$BUILD_NUMBER-staging"
elif [ "$CONFIGURATION" == "Prodbeta" ]; then
    target_app_name="$OPCO Prodbeta"
    target_icon_asset="tools/$OPCO/prodbeta"
    target_scheme="$OPCO-PRODBETA"
    target_app_center_app="Exelon-Digital-Projects/EU-Mobile-App-iOS-ProdBeta-$OPCO"
    target_version_number="$target_version_number.$BUILD_NUMBER-prodbeta"
elif [ "$CONFIGURATION" == "Hotfix" ]; then
    target_app_name="$OPCO Hotfix"
    target_icon_asset="tools/$OPCO/hotfix"
    target_scheme="$OPCO-HOTFIX"
    target_app_center_app="Exelon-Digital-Projects/EU-Mobile-App-iOS-Hotfix-$OPCO"
    target_version_number="$target_version_number.$BUILD_NUMBER-hotfix"
elif [ "$CONFIGURATION" == "Release" ]; then
    target_app_name="$OPCO"
    target_icon_asset="tools/$OPCO/release"
    target_scheme="$OPCO-RELEASE"
    target_app_center_app="Exelon-Digital-Projects/EU-Mobile-App-iOS-Prod-$OPCO"
else
    echo "Invalid argument: configuration"
    echo "    value must be either \"Testing\", \"Staging\", \"Prodbeta\", \"Hotfix\", or \"Release\""
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


if [[ $target_phases = *"build"* ]] || [[ $target_phases = *"appCenterTest"* ]]; then

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

	echo "Updating plist $PROJECT_DIR/App/Supporting\ Files/$OPCO/$OPCO-Info.plist"
    echo "Updating plist $PROJECT_DIR/Watch/Configuration/$OPCO-Info.plist"
    echo "Updating plist $PROJECT_DIR/Watch\ Extension/Configurations/$OPCO-Info.plist"

	# Update Bundle ID, App Name, App Version, and Icons
	plutil -replace CFBundleVersion -string $BUILD_NUMBER $PROJECT_DIR/App/Supporting\ Files/$OPCO/$OPCO-Info.plist
	plutil -replace CFBundleName -string "$target_app_name" $PROJECT_DIR/App/Supporting\ Files/$OPCO/$OPCO-Info.plist
	plutil -replace CFBundleShortVersionString -string $target_version_number $PROJECT_DIR/App/Supporting\ Files/$OPCO/$OPCO-Info.plist


    plutil -replace CFBundleVersion -string $BUILD_NUMBER $PROJECT_DIR/Watch/Configuration/$OPCO-Info.plist
    plutil -replace CFBundleName -string "$target_app_name" $PROJECT_DIR/Watch/Configuration/$OPCO-Info.plist
    plutil -replace CFBundleShortVersionString -string $target_version_number $PROJECT_DIR/Watch/Configuration/$OPCO-Info.plist

    plutil -replace CFBundleVersion -string $BUILD_NUMBER $PROJECT_DIR/Watch\ Extension/Configurations/$OPCO-Info.plist
    plutil -replace CFBundleName -string "$target_app_name" $PROJECT_DIR/Watch\ Extension/Configurations/$OPCO-Info.plist
    plutil -replace CFBundleShortVersionString -string $target_version_number $PROJECT_DIR/Watch\ Extension/Configurations/$OPCO-Info.plist


	echo "$PROJECT_DIR/App/Supporting\ Files/$OPCO/$OPCO-Info.plist updated:"
	echo "   CFBundleVersion=$BUILD_NUMBER"
	echo "   CFBundleName=$target_app_name"
	echo "   CFBundleShortVersionString=$target_version_number"
	echo ""

	if [[ ( "$CONFIGURATION" == "Staging"  ||  "$CONFIGURATION" == "Testing" ||  "$CONFIGURATION" == "Hotfix" ) &&  "$OVERRIDE_MBE" != "" ]]; then
        if find_in_array $OVERRIDE_MBE "${stagingMBEs[@]}"; then

            if [ "$CONFIGURATION" == "Staging" ]; then
                plutil -replace mcsInstanceName -string $OVERRIDE_MBE $PROJECT_DIR/App/Supporting\ Files/$OPCO/Environment/$OPCO-Environment-STAGING.plist
                echo "Updating plist $PROJECT_DIR/App/Supporting\ Files/$OPCO/Environment/$OPCO-Environment-STAGING.plist"
            elif [ "$CONFIGURATION" == "Hotfix" ]; then
                plutil -replace mcsInstanceName -string $OVERRIDE_MBE $PROJECT_DIR/App/Supporting\ Files/$OPCO/Environment/$OPCO-Environment-HOTFIX.plist
                echo "Updating plist $PROJECT_DIR/App/Supporting\ Files/$OPCO/Environment/$OPCO-Environment-HOTFIX.plist"
            else
                plutil -replace mcsInstanceName -string $OVERRIDE_MBE $PROJECT_DIR/App/Supporting\ Files/$OPCO/Environment/$OPCO-Environment-TESTING.plist
                echo "Updating plist $PROJECT_DIR/App/Supporting\ Files/$OPCO/Environment/$OPCO-Environment-TESTING.plist"
            fi
            echo "   mcsInstanceName=$OVERRIDE_MBE"
        else
            echo "Specified Stage MBE $OVERRIDE_MBE was not found"
            exit 1
        fi
    fi
fi


# Check VSTS xcode version. If set to 10, change it to 11. This branch requires 11+ to run.
if xcodebuild -version | grep -q "Xcode 10"; then
    echo "Switching VSTS build agent to Xcode 11 -- $XCODE_11_DEVELOPER_DIR"
    sudo xcode-select -switch $XCODE_11_DEVELOPER_DIR
fi

# Restore cocoapods Packages
if [[ $target_phases = *"cocoapods"* ]]; then
    pod repo update
    pod install
    check_errs $? "Cocoapods install exited with a non-zero status"
fi

if [[ $target_phases = *"unitTest"* ]]; then

    set -o pipefail

    echo "Running automation tests"
    xcrun xcodebuild \
        -workspace $PROJECT \
        -scheme "$OPCO-AUT" \
        -destination "$UNIT_TEST_SIMULATOR" \
        -configuration Automation \
        test | tee build/logs/xcodebuild_automation_unittests.log | xcpretty --report junit
    check_errs $? "Xcode unit tests exited with a non-zero status"

    set +o pipefail
fi

if [[ $target_phases = *"build"* ]]; then

    echo "------------------------------ Building Application  ----------------------------"
    # Build App

    set -o pipefail

	xcrun xcodebuild \
		-configuration $CONFIGURATION \
		-workspace $PROJECT \
		-scheme "$target_scheme" \
		-archivePath build/archive/$target_scheme.xcarchive \
		archive | tee build/logs/xcodebuild_archive.log | xcpretty

    check_errs $? "Xcode build exited with a non-zero status"

    echo "--------------------------------- Post archiving  -------------------------------"


    # Archive App
    xcrun xcodebuild \
        -exportArchive \
        -archivePath build/archive/$target_scheme.xcarchive \
        -exportPath build/output/$target_scheme \
        -exportOptionsPlist tools/ExportPlists/$target_scheme.plist

    check_errs $? "Xcode archiving exited with a non-zero status"

    echo "--------------------------------- Post exporting -------------------------------"

    set +o pipefail

    if [[ $target_phases = *"distribute"* ]]; then

        if [ -n "$AZURE_DEVOPS_TOKEN" ]; then
            echo "Azure dev ops token has been specified"

            if [ -n "$RELEASE_NOTES_PR_NUMBER" ]; then
                echo "Calling release notes script to generate release notes"
                 # disable error propagation. we do not want to force the whole build script to fail if the rm fails
                set +e
                pushd ./tools/release_notes_script/
                ./eucoms-list-changes.sh --target-project 'EU-mobile' --target-repo 'Exelon_Mobile_iOS' --target-repo-path '../../' --output txt --pull-request-number $RELEASE_NOTES_PR_NUMBER --token $AZURE_DEVOPS_TOKEN  --character-limit 4500
                popd

                set -e
            fi

        elif [ -n "$RELEASE_NOTES_CONTENT" ]; then
            echo "Release note contents were manually defined on the command line, outputing to tools/release_notes_script/release_notes.txt"
            echo "$RELEASE_NOTES_CONTENT" > "tools/release_notes_script/release_notes.txt"
        else
            echo "Skipping release notes generation"
        fi

        # Push to App Center Distribute
        echo "--------------------------------- Uploading release  -------------------------------"
        if [ -n "$APP_CENTER_GROUP" ] && [ -n "$APP_CENTER_API_TOKEN" ]; then

            appcenter distribute release \
                --app $target_app_center_app \
                --token $APP_CENTER_API_TOKEN \
                --file "build/output/$target_scheme/$target_scheme.ipa" \
                --group "$APP_CENTER_GROUP" \
                --release-notes-file "tools/release_notes_script/release_notes.txt"

            check_errs $? "App center distribution exited with a non-zero status"

        echo "--------------------------------- Completed release to $APP_CENTER_GROUP -------------------------------"
        else
            echo "Skipping App Center Distribution due to missing variables - \"app-center-group\" or \"app-center-api-token\""
        fi
    fi

    if [ "$CONFIGURATION" == "Release" ]; then
        echo "Skipping App Center symbol uploading as you will need to upload to Apple first and download dSYMs from them"
    else

        if [[ $target_phases = *"appCenterSymbols"* ]]; then
            echo "--------------------------------- Uploading symbols  -------------------------------"
            # Push to App Center Distribute
            if [ -n "$APP_CENTER_API_TOKEN" ]; then


                # disable error propagation. we do not want to force the whole build script to fail if the rm fails
                set +e

                rm -r build/appcentersymbols

                set -e

                mkdir build/appcentersymbols

                cp -a build/archive/$target_scheme.xcarchive/dSYMs/. build/appcentersymbols
                pushd ./build/appcentersymbols
                zip -r ../$OPCO-appcentersymbols-$target_version_number.zip .
                popd

                appcenter crashes upload-symbols -s \
                    ./build/$OPCO-appcentersymbols-$target_version_number.zip \
                    --app $target_app_center_app \
                    --token $APP_CENTER_API_TOKEN

            check_errs $? "App center crash uploading exited with a non-zero status"

                rm -r build/appcentersymbols

            echo "--------------------------------- Completed symbols  -------------------------------"

            else
                echo "Skipping App Center symbol uploading due to missing variables - \"app-center-api-token\""
            fi
        fi
    fi

    if [ "$CONFIGURATION" == "Release" ]; then
        echo "Skipping App Center distribution script as this is not applicable for prod release"
    else
    if [[ $target_phases = *"writeDistributionScript"* ]]; then
      echo "#!/usr/bin/env bash

APP_CENTER_API_TOKEN=
APP_CENTER_GROUP=

# Parse arguments.
for i in \"\$@\"; do
case \$1 in
    --app-center-api-token) APP_CENTER_API_TOKEN=\"\$2\"; shift ;;
    --app-center-group) APP_CENTER_GROUP=\"\$2\"; shift ;;
esac
shift
done

echo \"Uploading app to app center for distribution to group \$APP_CENTER_GROUP\"
appcenter distribute release \\
--app \"$target_app_center_app\" \\
--file \"build/output/$target_scheme/$target_scheme.ipa\" \\
--token \$APP_CENTER_API_TOKEN \\
--group \"\$APP_CENTER_GROUP\" \\
--release-notes-file \"tools/release_notes_script/release_notes.txt\"
" > ./tools/app_center_push.sh
    fi

fi
fi

if [[ $target_phases = *"nowsecure"* ]]; then

    if [ "$CONFIGURATION" == "Staging" ]; then

        if [ -n "$NOWSECURE_API_TOKEN" ]; then
            echo "Uploading ./build/output/$target_scheme/$target_scheme.ipa to NowSecure"
            pwd
            curl -H "Authorization: Bearer ${NOWSECURE_API_TOKEN}" -X POST https://lab-api.nowsecure.com/build/ --data-binary @./build/output/$target_scheme/$target_scheme.ipa
        else
            echo "NowSecure API token is missing, can't upload binary!"
        fi

    else
        echo "Skipping NowSecure upload. Only Staging configuration is setup for NowSecure analysis currently"
    fi
fi



if [[ $target_phases = *"appCenterTest"* ]]; then
    # Push to App Center Test

    if  [ -n "$APP_CENTER_API_TOKEN" ] && [ -n "$APP_CENTER_TEST_DEVICES" ]; then

        # disable error propagation. we do not want to force the whole build script to fail if the rm fails
        set +e

        rm -r build/Automation
        rm -r build/Mobile.build

        set -e

        # rm -rf "DerivedData"
        echo "----------------------------------- Build-for-testing -------------------------------"
        xcrun xcodebuild \
            -configuration Automation \
            -workspace $PROJECT \
            -scheme "$OPCO-AUT-UITest" \
            build-for-testing | tee build/logs/xcodebuild_build_for_testing.log | xcpretty

        check_errs $? "Build for testing exited with a non-zero status"

        # find .
        echo "--------------------------------- Uploading to appcenter -------------------------------"

        # xcode logs include a statement to output the location of the build directory
        $(grep "export BUILT_PRODUCTS_DIR" build/logs/xcodebuild_build_for_testing.log| head -n1)
        echo "Set environment variable BUILT_PRODUCTS_DIR to $BUILT_PRODUCTS_DIR"

        # Upload your test to App Center
        appcenter test run xcuitest \
            --app $target_app_center_app \
            --devices $APP_CENTER_TEST_DEVICES \
            --test-series "$APP_CENTER_TEST_SERIES"  \
            --locale "en_US" \
            --build-dir $BUILT_PRODUCTS_DIR \
            --token $APP_CENTER_API_TOKEN \
            --async

        check_errs $? "App center test upload exited with a non-zero status"

    else
        echo "Skipping App Center Test due to missing variables - \"app-center-test-devices\", or \"app-center-api-token\""
    fi
fi
