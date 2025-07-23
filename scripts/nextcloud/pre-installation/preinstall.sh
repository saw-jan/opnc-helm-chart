#!/bin/bash

set -eo pipefail

function wait_for_command() {
    local cmd="$1"
    local max_wait=300 # 5 minutes
    local wait_time=0
    local delay=5

    while [[ $wait_time -lt $max_wait ]]; do
        if command -v "$cmd" >/dev/null; then
            return 0
        fi
        echo "Waiting for '$cmd' to be available..."
        sleep "$delay"
        wait_time=$((wait_time + delay))
    done

    echo "Command '$cmd' not found after $max_wait seconds."
    exit 1
}

wait_for_command git
wait_for_command node
wait_for_command npm
wait_for_command composer

if [ -n "$NC_SERVE_GIT_BRANCH" ]; then
    echo "Pulling Nextcloud server from GitHub branch '${NC_SERVE_GIT_BRANCH}'..."
    SRC_DIR=/tmp/server
    rm -rf $SRC_DIR || true
    mkdir -p $SRC_DIR
    # get nextcloud server
    git clone --single-branch -b "${NC_SERVE_GIT_BRANCH}" --depth 1 https://github.com/nextcloud/server.git $SRC_DIR
    cd "$SRC_DIR"
    git config -f $SRC_DIR/.gitmodules submodule.3rdparty.shallow true
    git submodule update --init
    mkdir -p $SRC_DIR/custom_apps
    mkdir -p $SRC_DIR/data
    npm ci
    npm run build
    # sync server files to the web root
    rsync -rlD --delete --chmod=755 --chown=www-data:www-data $SRC_DIR/ /var/www/html
fi