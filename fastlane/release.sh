#!/usr/bin/env bash

sudo xcode-select -switch $XCODE_11_DEVELOPER_DIR

export FASTLANE_PASSWORD="$1"
OPCO="$2"


echo "Outputting the list of files we have to work with...."
find .

cd ./repo/
set -x

# update fastlane stuff
bundle update --bundler
fastlane update_plugins


# upload to appstore
fastlane uploadBuild --env $OPCO --verbose