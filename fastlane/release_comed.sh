#!/usr/bin/env bash

FASTLANE_PASSWORD=$1

cd ./_Exelon_Mobile_iOS/fastlane/
mv ../.././build/drop/build/xcarchive/COMED-RELEASE.xcarchive .

# update fastlane stuff
bundle update --bundler
fastlane update_plugins

# unzip and move files
find .

# upload to appstore
fastlane uploadBuild --env comed --verbose