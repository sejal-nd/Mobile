#!/bin/bash
# This script is designed to increment the build number consistently across all
# targets.

# Navigating to the 'EUDesignSystemExample' directory inside the source root.
#cd "$SRCROOT/$PRODUCT_NAME/tools"

# MARK: BUILD NUMBER

# Parse the 'Version.xcconfig' file to retrieve the previous build number.
# The 'awk' command is used to find the line containing "BUILD_NUMBER"
# and the 'tr' command is used to remove any spaces.
previous_build_number=$(awk -F "=" '/BUILD_NUMBER/ {print $2}' Version.xcconfig | tr -d ' ')

# Incrememnt build number
incremented_number=$((previous_build_number+1))

# New build number
new_build_number="${incremented_number}"

# Use 'sed' command to replace the previous build number with the new build
# number in the 'Version.xcconfig' file.
sed -i -e "/BUILD_NUMBER =/ s/= .*/= $new_build_number/" Version.xcconfig

echo "New build number set: ${new_build_number}."

# MARK: VERSION NUMBER

major=23
current_year=$(date "+%Y")
day_of_year=$(date "+%j")

# Parse the 'Version.xcconfig' file to retrieve the previous version number.
# The 'awk' command is used to find the line containing "VERSION"
# and the 'tr' command is used to remove any spaces.
previous_version_number=$(awk -F "=" '/VERSION/ {print $2}' Version.xcconfig | tr -d ' ')

new_version_number="${major}.${current_year}.${day_of_year}"

# Use 'sed' command to replace the previous build number with the new build
# number in the 'Version.xcconfig' file.
sed -i -e "/VERSION =/ s/= .*/= $new_version_number/" Version.xcconfig

echo "New version set: ${new_version_number}."

# Remove the backup file created by 'sed' command.
rm -f Version.xcconfig-e

if [ previous_build_number != new_build_number ]
then
   echo "Version and Build number successfully updated."
else
   exit 0
fi
