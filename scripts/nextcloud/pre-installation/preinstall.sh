#!/bin/bash

set -eo pipefail

WORKING_DIR=$(pwd)

function wait_for_command() {
    local cmd="$1"
    local max_wait=60
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
    SRC_DIR=/tmp/server
    # sync server files to the web root
    rsync -rlD --delete --chmod=755 --chown=www-data:www-data $SRC_DIR/ /var/www/html
    # npm ci
    # npm run build

    # max_wait=300 # 5 minutes
    # wait_time=0
    # delay=5
    # synced_file="/usr/src/nextcloud/synced"

    # while [ ! -f "$synced_file" ] && [ $wait_time -lt $max_wait ]; do
    #     echo "Waiting for Nextcloud source files to be ready..."
    #     sleep "$delay"
    #     wait_time=$((wait_time + delay))
    # done
    # if [ ! -f "$synced_file" ]; then
    #     echo "Nextcloud source files not ready after $max_wait seconds."
    #     exit 1
    # fi
fi