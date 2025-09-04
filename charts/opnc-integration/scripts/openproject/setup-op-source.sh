#!/bin/bash

set -eo pipefail

APP_PATH=/home/app/gitapp

echo "[INFO] Building OpenProject from source..."

if [[ -n $(ls -A "$APP_PATH") ]] && [[ "$OP_USE_LOCAL_SOURCE" != 'true' ]]; then
    echo "[ERROR] '$APP_PATH' is not empty. Please delete the volume and try again."
    exit 1
fi

mkdir -p "$APP_PATH" && cd "$APP_PATH"
chown $APP_USER:$APP_USER "$APP_PATH"

if [[ -n "$OP_GIT_SOURCE_BRANCH" ]] && [[ "$OP_USE_LOCAL_SOURCE" != 'true' ]]; then
    echo "[INFO] Cloning OpenProject from branch: $OP_GIT_SOURCE_BRANCH"
    git clone --branch "$OP_GIT_SOURCE_BRANCH" --depth 1 --single-branch "https://github.com/opf/openproject" "$APP_PATH"
fi

# trust git repos
git config --global safe.directory '*'

cd "$APP_PATH"
bash ./docker/prod/setup/bundle-install.sh
# remove source map and production optimizations from build to speed up build time
sed -i 's/ --configuration production --named-chunks --source-map//' ./frontend/package.json
DOCKER=0 NG_CLI_ANALYTICS="false" bash ./docker/prod/setup/precompile-assets.sh

sed -i 's|rm -f ./config/database.yml||' ./docker/prod/setup/postinstall-common.sh
rm -f ./config/database.yml
cp ./config/database.production.yml ./config/database.yml
rm -rf "$APP_PATH/tmp"

# set sticky bit on app path and tmp directory
chmod +t "$APP_PATH"
chmod +t "/tmp"

touch build-completed