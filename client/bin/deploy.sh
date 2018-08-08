#!/bin/bash

set -euo pipefail

main() {
    parse_arguments "$@"
    header "Checking repo is clean"
    abort_if_uncommitted_changes_present
    header "Deploying to ${REMOTE}"
    deploy
}

abort_if_uncommitted_changes_present() {
    if ! git diff-index --quiet HEAD ; then
        echo "$0: Uncommitted changes present aborting. Either stash or commit."
        exit 2
    fi
}

deploy() {
    git push ${REMOTE} -f HEAD:master 2> >(indent 1>&2) | indent
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

usage() {
    echo "Usage: $(basename $0) [options]"
    echo
    echo "Deploy HEAD to a dokku app"
    echo
    echo -e "      --production\t\tDeploy to the production environment"
    echo -e "      --help\t\tShow this help message"
}

REMOTE=dokku-staging

parse_arguments() {
    while [[ $# > 0 ]] ; do
        key="$1"

        case $key in
            --production)
                REMOTE=dokku
                shift
                ;;

            --test)
                REMOTE=dokku-test
                shift
                ;;

            --help)
                usage
                exit 0
                ;;

            *)
                echo "$(basename $0): unrecognized option ${key}"
                usage
                exit 1
                ;;
        esac
    done
}

main "$@"
