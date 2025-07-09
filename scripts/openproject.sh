#!/bin/bash

set -eo pipefail

rm -rf /etc/ssl/certs/OPNC_Root_CA.pem /usr/local/share/ca-certificates/OPNC_Root_CA.crt
cp /certs/ca.crt /usr/local/share/ca-certificates/OPNC_Root_CA.crt
update-ca-certificates

if [[ -n "$OP_GIT_SOURCE_BRANCH" ]]; then
    APP_PATH=/appgit
    mkdir $APP_PATH && cd $APP_PATH
    export APP_PATH

    git clone --branch "$OP_GIT_SOURCE_BRANCH" --depth 1 --single-branch "https://github.com/opf/openproject" "$APP_PATH"

    "$APP_PATH"/docker/prod/setup/bundle-install.sh
    "$APP_PATH"/docker/prod/setup/precompile-assets.sh
    "$APP_PATH"/docker/prod/setup/postinstall-common.sh

    rm -f "$APP_PATH"/config/database.yml
    cp "$APP_PATH"/config/database.production.yml "$APP_PATH"/config/database.yml
    ln -s "$APP_PATH"/docker/prod/setup/.irbrc /home/"$APP_USER"/
fi

./docker/prod/entrypoint.sh ./docker/prod/supervisord
