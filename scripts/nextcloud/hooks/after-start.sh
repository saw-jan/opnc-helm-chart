#!/bin/bash

set -e

has_integration_setup() {
    local response
    local setup_without_project_folder
    local setup_with_project_folder

    response=$(curl -s -XGET -uadmin:admin \
        "https://$VIRTUAL_HOST/index.php/apps/integration_openproject/check-admin-config" \
        -H 'Content-Type: application/json')
    setup_without_project_folder=$(echo "$response" | jq -r ".config_status_without_project_folder")
    setup_with_project_folder=$(echo "$response" | jq -r ".project_folder_setup_status")

    if [[ "$setup_without_project_folder" == "true" || "$setup_with_project_folder" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# waits 5 minutes for the server to be ready
wait_for_server() {
    local url="$1"
    local max_retry=60
    local retry=1

    while [[ $retry -le $max_retry ]]; do
        if [[ $(curl -s -o /dev/null -w "%{http_code}" "$url") -lt 400 ]]; then
            return 0
        fi
        echo "[INFO] Waiting for '$url' to be ready... (Retry $retry/$max_retry)"
        sleep 5
        ((retry++))
    done

    echo "[Timeout] Server is not ready: $url"
    return 1
}

# shellcheck source=/dev/null
source ~/.bashrc
WORKING_DIR=$(pwd)
APP_DIR="apps/integration_openproject"

occ a:d integration_openproject
rm -rf $APP_DIR || true

if [[ -n "$INTEGRATION_APP_GIT_BRANCH" ]]; then
    mkdir -p $APP_DIR
    echo "[INFO] Using 'integration_openproject' app branch: ${INTEGRATION_APP_GIT_BRANCH}"
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

if has_integration_setup; then
    echo "[INFO] Integration app is already set up."
    exit 0
fi

if [[ "$INTEGRATION_APP_SETUP_METHOD" != "oauth2" && "$INTEGRATION_APP_SETUP_METHOD" != "sso-nextcloud" && "$INTEGRATION_APP_SETUP_METHOD" != "sso-external" ]]; then
    echo "[ERROR] Invalid INTEGRATION_APP_SETUP_METHOD: $INTEGRATION_APP_SETUP_METHOD"
    echo "[ERROR] Valid options are: 'oauth2', 'sso-nextcloud', 'sso-external'"
    exit 1
fi

# wait for servers
echo "[INFO] Waiting for OpenProject to be ready..."
wait_for_server "https://$OPENPROJECT_HOST"
echo "[INFO] OpenProject is ready."

# Setup integration app
cd $APP_DIR
if [[ "$INTEGRATION_APP_SETUP_METHOD" == "oauth2" ]]; then
    curl -s https://raw.githubusercontent.com/nextcloud/integration_openproject/master/integration_setup.sh -o integration_setup.sh

    SETUP_PROJECT_FOLDER='true' \
        NEXTCLOUD_HOST=https://$VIRTUAL_HOST \
        NC_ADMIN_USERNAME=admin \
        NC_ADMIN_PASSWORD=admin \
        OPENPROJECT_HOST=https://$OPENPROJECT_HOST \
        OP_ADMIN_USERNAME='admin' \
        OP_ADMIN_PASSWORD='admin' \
        OPENPROJECT_STORAGE_NAME='nextcloud' \
        bash integration_setup.sh

elif [[ "$INTEGRATION_APP_SETUP_METHOD" == "sso-nextcloud" ]]; then
    curl -s https://raw.githubusercontent.com/nextcloud/integration_openproject/master/integration_oidc_setup.sh -o integration_oidc_setup.sh

    NC_HOST=https://$VIRTUAL_HOST \
        NC_ADMIN_USERNAME=admin \
        NC_ADMIN_PASSWORD=admin \
        NC_INTEGRATION_PROVIDER_TYPE=external \
        NC_INTEGRATION_PROVIDER_NAME=Keycloak \
        NC_INTEGRATION_OP_CLIENT_ID=openproject \
        NC_INTEGRATION_TOKEN_EXCHANGE=true \
        NC_INTEGRATION_ENABLE_NAVIGATION=false \
        NC_INTEGRATION_ENABLE_SEARCH=false \
        OP_HOST=https://$OPENPROJECT_HOST \
        OP_ADMIN_USERNAME=admin \
        OP_ADMIN_PASSWORD=admin \
        OP_STORAGE_NAME=nextcloud \
        OP_STORAGE_AUDIENCE=nextcloud \
        bash integration_oidc_setup.sh

elif [[ "$INTEGRATION_APP_SETUP_METHOD" == "sso-external" ]]; then
    echo "[INFO] Waiting for Keycloak to be ready..."
    wait_for_server "https://$KEYCLOAK_HOST"
    echo "[INFO] Keycloak is ready."

    curl -s https://raw.githubusercontent.com/nextcloud/integration_openproject/master/integration_oidc_setup.sh -o integration_oidc_setup.sh

    NC_INTEGRATION_PROVIDER_TYPE=nextcloud_hub \
        NC_ADMIN_USERNAME=admin \
        NC_ADMIN_PASSWORD=admin \
        NC_INTEGRATION_ENABLE_NAVIGATION=false \
        NC_INTEGRATION_ENABLE_SEARCH=false \
        NC_HOST=https://$VIRTUAL_HOST \
        OP_ADMIN_USERNAME=admin \
        OP_ADMIN_PASSWORD=admin \
        OP_STORAGE_NAME=nextcloud \
        OP_HOST=https://$OPENPROJECT_HOST \
        OP_USE_LOGIN_TOKEN=true \
        bash integration_oidc_setup.sh
fi
