#!/usr/bin/env bash
set -x

export FASTLANE_PASSWORD="$1"

cd ./_Exelon_Mobile_iOS/fastlane/
mv ../.././build/drop/build/xcarchive/$OPCO-RELEASE.xcarchive .

# update fastlane stuff
bundle update --bundler
fastlane update_plugins

# unzip and move files
find .

# upload to appstore
fastlane uploadBuild --env $OPCO --verbose