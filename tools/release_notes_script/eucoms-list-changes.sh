#!/usr/bin/env bash

ROOT=$(pwd)

# Defaults to EUCOMS
TARGET_PROJECT=EUCOMS
TARGET_REPO=EUCOMS
TARGET_BRANCH=master
SOURCE_BRANCH=stage
TARGET_REPO_PATH=EUCOMS
TOKEN="$(cat $ROOT/token.txt)"
OUTPUTFORMAT=csv
PULL_REQUEST_NUMBER=
CHARACTER_LIMIT=

# Parse arguments.
for i in "$@"; do
    case $1 in
        --target-project) TARGET_PROJECT="$2"; shift ;;
        --target-repo) TARGET_REPO="$2"; shift ;;
        --target-repo-path) TARGET_REPO_PATH="$2"; shift ;;
        --target-branch) TARGET_BRANCH="$2"; shift ;;
        --source-branch) SOURCE_BRANCH="$2"; shift ;;
        --token) TOKEN="$2"; shift ;;
        --output) OUTPUTFORMAT="$2"; shift ;;
        --pull-request-number) PULL_REQUEST_NUMBER="$2"; shift ;;
        --character-limit) CHARACTER_LIMIT="$2"; shift ;;
    esac
    shift
done

AZURE_DEVOPS_URL=https://exelontfs.visualstudio.com/${TARGET_PROJECT}/_git/${TARGET_REPO}


if [ -z "$TOKEN" ]; then
    printf "Please save a personal access token to ${ROOT}/token.txt or use the --token parameter\n" 1>&2
    exit 1
fi

if [ -z "$PULL_REQUEST_NUMBER" ]; then

    if [[ ! -d "${TARGET_REPO_PATH}" ]]; then
        git clone --bare "${AZURE_DEVOPS_URL}" "${TARGET_REPO_PATH}"
    fi

    pushd "${TARGET_REPO_PATH}"
    git fetch
    git log --first-parent ${TARGET_BRANCH}..${SOURCE_BRANCH} | \
    grep -i "work items" | \
    sed 's/Related work items: //' | \
    perl -pe "s,#(\d+),https://exelontfs.visualstudio.com/${TARGET_PROJECT}/_workitems/edit/\$1,g; s/,/\n/g; s/ +//g;" | \
    sort | \
    uniq > $ROOT/work-items.txt

    git log --first-parent ${TARGET_BRANCH}..${SOURCE_BRANCH} | \
    grep -i "merged pr" | \
    perl -ne "print \"https://exelontfs.visualstudio.com/${TARGET_PROJECT}/_git/${TARGET_REPO}/pullrequest/\${1}\n\" if m/merged pr (\d+)/i;" |
    sort | \
    uniq > $ROOT/pull-reqs.txt
else
    
    # We are only looking at a single specified pull request instead of basing it on git commit logs
    echo "https://exelontfs.visualstudio.com/${TARGET_PROJECT}/_git/${TARGET_REPO}/pullrequest/${PULL_REQUEST_NUMBER}" > $ROOT/pull-reqs.txt

fi


if [ "$OUTPUTFORMAT" == "csv" ]; then
    printf "Pull Request\tTitle\tNotes\tURL\n" > $ROOT/pull-reqs.csv
elif [ "$OUTPUTFORMAT" == "txt" ]; then
    rm $ROOT/release_notes.txt
    touch $ROOT/release_notes.txt
fi


while read line; do
    
    pr="$(basename $line)"
    url="https://dev.azure.com/exelontfs/_apis/git/pullrequests/${pr}?api-version=4.1"

    curl -u "${TOKEN}" "${url}" > $ROOT/pr_details.txt
    title=$(cat $ROOT/pr_details.txt | jq -r '.title')
    desc=$(cat $ROOT/pr_details.txt | jq -r '.description')
    pr_creator=$(cat $ROOT/pr_details.txt | jq -r '.createdBy.displayName')

    pr_source_branch=$(cat $ROOT/pr_details.txt | jq -r '.sourceRefName')
    pr_target_branch=$(cat $ROOT/pr_details.txt | jq -r '.targetRefName')
    
    # clean up branch names for display purposes
    pr_source_branch=${pr_source_branch//refs\/heads\/}
    pr_target_branch=${pr_target_branch//refs\/heads\/}

    detailed_url=$(cat $ROOT/pr_details.txt | jq -r '.repository.url')

    if [ "$OUTPUTFORMAT" == "csv" ]; then
        printf "%s\t%s\t%s\t%s\n" "$pr" "$title" "${desc}" "$line" >> $ROOT/pull-reqs.csv
    elif [ "$OUTPUTFORMAT" == "txt" ]; then
        echo "# ${title}" >> $ROOT/release_notes.txt
        echo "" >> $ROOT/release_notes.txt
        echo "[Pull request #${pr}]($line) initiated by ${pr_creator}" >> $ROOT/release_notes.txt
        echo "Merging branch ${pr_source_branch} into ${pr_target_branch}" >> $ROOT/release_notes.txt
        if [ -n "$desc" ] && [ "$desc" != "null" ]; then
            printf "\nPull request description\n----------------------------\n" >> $ROOT/release_notes.txt
            echo "${desc}" >> $ROOT/release_notes.txt
        fi

    fi 

    echo "Fetching info about the pull request work items"
    if [ -n "$PULL_REQUEST_NUMBER" ]; then

        url="${detailed_url}/pullRequests/${pr}/workitems?api-version=4.1"
        
        curl -u "${TOKEN}" "${url}" > $ROOT/pr_work_items.txt

        cat $ROOT/pr_work_items.txt | jq -r '.value[].id' > $ROOT/pr_work_item_ids.txt

        echo "Fetching work items..."

        rm $ROOT/work-items.txt 
        touch $ROOT/work-items.txt
        while read workitemid; do
            item="$(basename $workitemid)"
            
            echo "https://exelontfs.visualstudio.com/${TARGET_PROJECT}/_workitems/edit/${item} " >> $ROOT/work-items.txt
            
        done < $ROOT/pr_work_item_ids.txt
    fi

    rm $ROOT/pr_details.txt
    rm $ROOT/pr_work_item_ids

done < $ROOT/pull-reqs.txt


if [ "$OUTPUTFORMAT" == "csv" ]; then
    printf "Work Item\tTitle\tURL\n" > $ROOT/work-items.csv
elif [ "$OUTPUTFORMAT" == "txt" ]; then
    printf "\nLinked Work Items\n----------------------------\n" >> $ROOT/release_notes.txt
fi

while read line; do

    item="$(basename $line)"
    echo "Requesting work item details for $line"
    url="https://dev.azure.com/exelontfs/${TARGET_PROJECT}/_apis/wit/workitems/${item}?api-version=4.1"
    title=$(curl -u "${TOKEN}" "${url}" | jq -r '.fields["System.Title"]')
    
    if [ "$OUTPUTFORMAT" == "csv" ]; then
        printf "%s\t%s\t%s\n" "$item" "$title" "$line" >> $ROOT/work-items.csv
    elif [ "$OUTPUTFORMAT" == "txt" ]; then
        echo "- [${item} - ${title}](${line})" >> $ROOT/release_notes.txt
        
        if [ -n "$CHARACTER_LIMIT" ]; then
            wordcount=$(wc -m $ROOT/release_notes.txt | awk '{print $1}')
            if [ "$wordcount" -gt "$CHARACTER_LIMIT" ]; then
                echo "-- Character limit exceeded, output truncated --"
                echo "-- Character limit exceeded, output truncated --" >> $ROOT/release_notes.txt
                break
            fi
            
        fi
    fi
done < $ROOT/work-items.txt



rm $ROOT/work-items.txt
rm $ROOT/pull-reqs.txt
