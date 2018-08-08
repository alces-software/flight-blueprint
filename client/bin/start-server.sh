#!/bin/bash

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)

source <( cat "${REPO_ROOT}/.env" \
    | grep -v '^ *#' \
    | sed '/^ *$/d' \
    | sed 's/^/export /'
)

yarn run start:server
