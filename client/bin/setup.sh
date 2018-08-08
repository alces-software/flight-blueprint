#!/bin/bash

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Flight Ltd.
#
# This file is part of Alces Launch.
#
# All rights reserved, see LICENSE.txt.
#==============================================================================
set -eu
set -o pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

main() {
    parse_arguments "$@"
    check_dependencies
    setup
}

setup() {
    cd "${REPO_ROOT}"
    subheader "Creating .env file (if it doesn't exist)"
    cp -an .env.example .env
    subheader "Installing packages"
    yarn 2> >(indent 1>&2) | indent

    # Make sure the prompt isn't indented.
    echo
}

usage() {
    echo "Usage: $(basename $0)"
    echo
    echo "Build the flight terminal services client."
}


check_dependencies() {
    :
}

parse_arguments() {
    while [[ $# > 0 ]] ; do
        key="$1"

        case $key in
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

header() {
    echo -e "\n>>> $@ <<<"
}

subheader() {
    echo -e " ---> $@"
}

indent() {
    sed 's/^/  /'
}

main "$@"
