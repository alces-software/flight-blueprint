#!/bin/bash

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
VERSION_FILE="${REPO_ROOT}/src/data/version.json"

main() {
    header "Checking repo is clean"
    abort_if_uncommitted_changes_present

    NEW_VERSION=$(get_new_version)
    header "Going to deploy, tag and push version ${NEW_VERSION}"
    wait_for_confirmation

    subheader "Creating release branch"
    checkout_release_branch
    subheader "Bumping version"
    bump_version
    commit_version_bump
    subheader "Building licensables"
    build_and_commit_licensables

    header "Running deploy script"
    run_deploy_script

    echo ""
    echo "${NEW_VERSION} has been deployed to staging app."
    echo "Test that all is good and then we'll deploy to production"
    wait_for_confirmation
    run_deploy_script --production

    echo ""
    echo "App has been deployed to production."
    echo "Test that all is good and then we'll continue with tag creation and pushing"
    wait_for_confirmation

    header "Merging, tagging, and pushing"
    run_merge_script
}

abort_if_uncommitted_changes_present() {
    if ! git diff-index --quiet HEAD ; then
        echo "$0: Uncommitted changes present aborting. Either stash or commit."
        exit 2
    fi
}

get_new_version() {
    "${REPO_ROOT}"/bin/bump_version.rb "${VERSION_FILE}" --dry-run \
        | jq -r '(.major|tostring) + "." + (.minor|tostring)'
}

bump_version() {
    "${REPO_ROOT}"/bin/bump_version.rb "${VERSION_FILE}"
}

checkout_release_branch() {
    git checkout -b release/"${NEW_VERSION}"
}

commit_version_bump() {
    git commit -m "Bump version to ${NEW_VERSION}" "${VERSION_FILE}"
}

build_and_commit_licensables() {
    (
    cd "${REPO_ROOT}"
    yarn run build:licensables
    if [ $( git status --porcelain src/data/licenses.json | wc -l ) -eq 0 ] ; then
        echo "Licensables up-to-date"
    else
        git commit -m 'Updated licenses.json' src/data/licenses.json
    fi
    ) 2> >(indent 1>&2) | indent
}

run_deploy_script() {
    "${REPO_ROOT}"/bin/deploy.sh "$@"
}

run_merge_script() {
    "${REPO_ROOT}"/bin/merge-and-tag-release.sh "${NEW_VERSION}"

}

wait_for_confirmation() {
    echo ""
    echo "Press enter to continue or Ctrl-C to abort like a coward"
    read -s
}

header() {
    echo -e "=====> $@"
}

subheader() {
    echo -e "-----> $@"
}

indent() {
    sed 's/^/       /'
}

main "$@"
