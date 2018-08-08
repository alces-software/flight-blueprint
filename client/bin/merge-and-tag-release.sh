#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

main() {
    local release_tag release_branch

    if (( $# != 1 )); then
        echo "$0: Please provide tag name for release, e.g. '201610.1'"
        echo "$0: Note that associated branch name should also already exist, e.g. 'release/201610.1'"
        exit 1
    fi

    abort_if_uncommitted_changes_present

    release_tag="$1"
    release_branch="release/${release_tag}"

    git fetch origin
    merge_and_tag
}

abort_if_uncommitted_changes_present() {
    if ! git diff-index --quiet HEAD ; then
        echo "$0: Uncommitted changes present aborting."
        exit 2
    fi
}

abort_if_not_uptodate_with_remote() {
    local local_rev remote_rev base_rev

    local_rev=$(git rev-parse HEAD)
    remote_rev=$(git rev-parse @{upstream})
    base_rev=$(git merge-base @ @{u})

    if [ $local_rev = $remote_rev ]; then
        # Everything is good.
        return 0
    elif [ $local_rev = $base_rev ]; then
        echo "Local branch not up-to-date.  You need to pull in the remote changes."
        exit 3
    elif [ $remote_rev = $base_rev ]; then
        echo "Local branch has unpushed changes.  Oops!"
        exit 4
    else
        echo "Local and remote branches have diverged.  Oh dear!!"
        exit 5
    fi
}

merge_and_tag() {
    git checkout master
    abort_if_not_uptodate_with_remote
    git merge --no-ff "$release_branch"
    git tag -a "$release_tag" -m "Tag for release as $release_tag"

    git checkout develop
    abort_if_not_uptodate_with_remote
    git merge --no-ff "$release_branch"

    git push --follow-tags origin master
    git push origin develop

    git branch -d "$release_branch"
}

main "$@"
