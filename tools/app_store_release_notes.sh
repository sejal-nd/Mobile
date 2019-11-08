#!/usr/bin/env bash

ROOT=$(pwd)

# Defaults to EUCOMS
TARGET_PROJECT=EU-Mobile
RELEASE_ID=
TOKEN="$(cat $ROOT/token.txt)"
OPCO=

# Parse arguments.
for i in "$@"; do
    case $1 in
        --target-project) TARGET_PROJECT="$2"; shift ;;
        --release-id) RELEASE_ID="$2"; shift ;;
        --token) TOKEN="$2"; shift ;;
        --opco) OPCO="$2"; shift ;;
    esac
    shift
done

AZURE_DEVOPS_URL=https://vsrm.dev.azure.com/exelontfs/${TARGET_PROJECT}/_apis/Release/releases/${RELEASE_ID}/manualinterventions?api-version=5.1

if [ -z "$TOKEN" ]; then
    printf "Please save a personal access token to ${ROOT}/token.txt or use the --token parameter\n" 1>&2
    exit 1
fi

curl -u "${TOKEN}" "${AZURE_DEVOPS_URL}" > $ROOT/release_notes.json

OUTPUTPATH=./fastlane/metadata/$OPCO/en-US/release_notes.txt

touch $OUTPUTPATH

cat release_notes.json | jq -r '.value[].comments' > $OUTPUTPATH

rm release_notes.json


