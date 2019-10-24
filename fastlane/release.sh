#!/usr/bin/env bash
set -x

sudo xcode-select -switch $XCODE_11_DEVELOPER_DIR

export FASTLANE_PASSWORD="$1"
OPCO="$2"

cd ./repo/
mv ../.././build/drop/build/ ./fastlane

find .

# update fastlane stuff
bundle update --bundler
fastlane update_plugins


# upload to appstore
fastlane uploadBuild --env $OPCO --verbose