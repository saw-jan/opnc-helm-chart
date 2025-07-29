#!/bin/bash

set -eo pipefail

if [[ -n "$OP_GIT_SOURCE_BRANCH" ]]; then
    APP_PATH=$HOME/appgit
    mkdir "$APP_PATH" && cd "$APP_PATH"
    export APP_PATH

    echo "Cloning OpenProject from branch: $OP_GIT_SOURCE_BRANCH"
    git clone --branch "$OP_GIT_SOURCE_BRANCH" --depth 1 --single-branch "https://github.com/opf/openproject" "$APP_PATH"

    bash "$APP_PATH"/docker/prod/setup/bundle-install.sh
    bash "$APP_PATH"/docker/prod/setup/precompile-assets.sh
    bash "$APP_PATH"/docker/prod/setup/postinstall-common.sh

    rm -f "$APP_PATH"/config/database.yml
    cp "$APP_PATH"/config/database.production.yml "$APP_PATH"/config/database.yml
    rm -f "$HOME/.irbrc"
    ln -s "$APP_PATH"/docker/prod/setup/.irbrc /home/"$APP_USER"/
fi

args=()
for arg in "$@"; do
    arg="${arg//\/app\//./}"
    args+=("$arg")
done

cd "$APP_PATH"

./docker/prod/entrypoint.sh "${args[@]}"
