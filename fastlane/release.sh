#!/usr/bin/env bash
set -x

export FASTLANE_PASSWORD="$1"
OPCO="$2"

# unzip and move files
find .

cd ./repo/fastlane/
mv ../.././build/drop/build/xcarchive/$OPCO-RELEASE.xcarchive .

# update fastlane stuff
bundle update --bundler
fastlane update_plugins


# upload to appstore
fastlane uploadBuild --env $OPCO --verbose