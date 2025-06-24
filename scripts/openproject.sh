#!/bin/bash

rm -rf /etc/ssl/certs/OPNC_Root_CA.pem /usr/local/share/ca-certificates/OPNC_Root_CA.crt
cp /certs/ca.crt /usr/local/share/ca-certificates/OPNC_Root_CA.crt
update-ca-certificates

if [[ -z "$USE_CUSTOM_SOURCE" && -n "$GIT_SOURCE_BRANCH" ]]; then
    USE_CUSTOM_SOURCE="true"
    set -x
    rm -rf "$APP_PATH"
    git clone --branch "$GIT_SOURCE_BRANCH" --depth 1 --single-branch "https://github.com/opf/openproject" /app
    chown -R "$APP_USER:$APP_USER" "$APP_PATH/"
    chmod -R 755 "$APP_PATH/"
    "$APP_PATH"/docker/prod/setup/bundle-install.sh
    "$APP_PATH"/docker/prod/setup/precompile-assets.sh
    set +x
fi

if [[ -n "$USE_CUSTOM_SOURCE" && "$USE_CUSTOM_SOURCE" == "true" ]]; then
    set -x

    chown -R "$APP_USER:$APP_USER" "$APP_PATH/"

    "$APP_PATH"/docker/prod/setup/postinstall-common.sh
    rm -f "$APP_PATH"/config/database.yml
    cp "$APP_PATH"/config/database.production.yml "$APP_PATH"/config/database.yml
    set +x
fi

./docker/prod/entrypoint.sh ./docker/prod/supervisord
