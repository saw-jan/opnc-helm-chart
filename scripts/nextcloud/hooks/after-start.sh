#!/bin/bash

set -e

if [[ -n "$INTEGRATION_APP_GIT_BRANCH" ]]; then
    # shellcheck source=/dev/null
    source ~/.bashrc
    WORKING_DIR=$(pwd)

    echo "Using 'integration_openproject' app branch: ${INTEGRATION_APP_GIT_BRANCH}"
    APP_DIR="custom_apps/integration_openproject"
    rm -rf $APP_DIR || true
    mkdir -p $APP_DIR
    git clone --single-branch \
        -b "${INTEGRATION_APP_GIT_BRANCH}" \
        --depth 1 \
        https://github.com/nextcloud/integration_openproject.git $APP_DIR
    cd $APP_DIR
    composer install --no-dev
    npm ci && npm run dev
    cd "$WORKING_DIR"
    occ a:e integration_openproject
fi
