#!/bin/bash

set -e

# shellcheck source=/dev/null
source ~/.bashrc
WORKING_DIR=$(pwd)
APP_DIR="apps/integration_openproject"

occ a:d integration_openproject
rm -rf $APP_DIR || true

if [[ -n "$INTEGRATION_APP_GIT_BRANCH" ]]; then
    mkdir -p $APP_DIR
    echo "Using 'integration_openproject' app branch: ${INTEGRATION_APP_GIT_BRANCH}"
    git clone --single-branch \
        -b "${INTEGRATION_APP_GIT_BRANCH}" \
        --depth 1 \
        https://github.com/nextcloud/integration_openproject.git $APP_DIR
    cd $APP_DIR
    composer install --no-dev
    npm ci && npm run dev
elif [[ -n "$INTEGRATION_APP_VERSION" ]]; then
    mkdir -p $APP_DIR
    curl -sL "https://github.com/nextcloud/integration_openproject/releases/download/v$INTEGRATION_APP_VERSION/integration_openproject-$INTEGRATION_APP_VERSION.tar.gz" | tar -xz -C $APP_DIR --strip-components=1
fi

cd "$WORKING_DIR"
occ a:e integration_openproject
occ upgrade
