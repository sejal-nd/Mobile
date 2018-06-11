#!/usr/bin/env bash

APP_CENTER_API_TOKEN=
APP_CENTER_GROUP=

# Parse arguments.
for i in "$@"; do
case $1 in
    --app-center-api-token) APP_CENTER_API_TOKEN="$2"; shift ;;
    --app-center-group) APP_CENTER_GROUP="$2"; shift ;;
esac
shift
done

echo "Uploading app to app center for distribution to group $APP_CENTER_GROUP"
appcenter distribute release \
--app "Exelon-Digital-Projects/EU-Mobile-App-iOS-Stage-BGE" \
--file "build/output/BGE-STAGING/BGE-STAGING.ipa" \
--token $APP_CENTER_API_TOKEN \
--group "$APP_CENTER_GROUP"

