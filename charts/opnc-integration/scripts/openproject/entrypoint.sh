#!/bin/bash

set -eo pipefail

cd "$APP_PATH"

if [[ -n "$OP_GIT_SOURCE_BRANCH" || "$OP_USE_LOCAL_SOURCE" == 'true' ]]; then
    while [[ ! -f "$APP_PATH/build-completed" ]]; do
        echo "[INFO] Waiting build from source to complete..."
        sleep 10
    done
    bash ./docker/prod/setup/postinstall-common.sh
fi

args=()
for arg in "$@"; do
    # Replace '/app/'' with './'
    arg="${arg//\/app\//./}"
    args+=("$arg")
done

./docker/prod/entrypoint.sh "${args[@]}"
