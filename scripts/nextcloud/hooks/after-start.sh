#!/bin/bash

set -eo pipefail

# shellcheck source=/dev/null
source ~/.bashrc
WORKING_DIR=$(pwd)

###################################
# Enable apps                     #
###################################
OLD_IFS=$IFS
# trim leading and trailing whitespaces
NEXTCLOUD_ENABLE_APPS=$(echo "$NEXTCLOUD_ENABLE_APPS" | xargs)
for app in $NEXTCLOUD_ENABLE_APPS; do
    IFS="@" read -r app_name app_version <<<"$app"
    IFS=$OLD_IFS

    APP_DIR="apps/$app_name"

    occ a:d "$app_name"
    rm -rf "$APP_DIR" || true

    GIT_REPO_URL="https://github.com/nextcloud/$app_name"
    if [[ "$app_name" == "oidc" ]]; then
        GIT_REPO_URL="https://github.com/H2CK/$app_name"
    fi

    if [[ -z "$app_version" ]]; then
        echo "[INFO] Enabling app '$app_name': latest"
    elif [[ "$app_version" =~ "git="* ]]; then
        mkdir -p "$APP_DIR"
        # extract the branch name
        app_branch=${app_version#git=}
        echo "[INFO] Enabling app '$app_name': '$app_branch' branch"

        git clone --single-branch \
            -b "$app_branch" \
            --depth 1 \
            "${GIT_REPO_URL}.git" "$APP_DIR"

        cd "$APP_DIR"
        composer install --no-dev
        npm ci && npm run dev
    else
        mkdir -p "$APP_DIR"
        echo "[INFO] Enabling app '$app_name': $app_version"
        RELEASE_ARCHIVE_URL="$GIT_REPO_URL/releases/download/v$app_version/$app_name-$app_version.tar.gz"
        if [[ $(curl -s -o /dev/null -w "%{http_code}" "$RELEASE_ARCHIVE_URL") == 404 ]]; then
            # try without 'v' prefix
            RELEASE_ARCHIVE_URL="$GIT_REPO_URL/releases/download/$app_version/$app_name-$app_version.tar.gz"
        fi
        # download source from tag archive if release asset is not found
        if [[ $(curl -s -o /dev/null -w "%{http_code}" "$RELEASE_ARCHIVE_URL") == 404 ]]; then
            TAG_ARCHIVE_URL="$GIT_REPO_URL/archive/refs/tags/v$app_version.tar.gz"
            if [[ $(curl -s -o /dev/null -w "%{http_code}" "$TAG_ARCHIVE_URL") == 404 ]]; then
                # try without 'v' prefix
                TAG_ARCHIVE_URL="$GIT_REPO_URL/archive/refs/tags/$app_version.tar.gz"
            fi
            if [[ $(curl -s -o /dev/null -w "%{http_code}" "$TAG_ARCHIVE_URL") == 404 ]]; then
                echo "[ERROR] Cannot find app '$app_name' with version '$app_version': $GIT_REPO_URL"
                echo -e "\tTry with out the 'v' prefix in the version number."
                continue
            fi
            curl -sL "$RELEASE_ARCHIVE_URL" | tar -xz -C "$APP_DIR" --strip-components=1
            # build the source
            cd "$APP_DIR"
            composer install --no-dev
            npm ci && npm run dev
        else
            curl -sL "$RELEASE_ARCHIVE_URL" | tar -xz -C "$APP_DIR" --strip-components=1
        fi
    fi

    cd "$WORKING_DIR"
    # enable the app
    occ a:e "$app_name"
done

# upgrade Nextcloud apps
occ upgrade

###################################
# Setup integration app           #
###################################
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
        server_status=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")
        if [[ $server_status -ne 0 && $server_status -lt 400 ]]; then
            return 0
        fi
        echo "[INFO] Waiting for '$url' to be ready... (Retry $retry/$max_retry)"
        sleep 5
        ((retry++))
    done

    echo "[Timeout] Server is not ready: $url"
    return 1
}

if [[ ! -d "apps/integration_openproject" ]]; then
    echo "[INFO] integration_openproject app is not installed. Skipping integration setup."
    exit 0
fi

if has_integration_setup; then
    echo "[INFO] Integration app is already set up. Skipping integration setup."
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

cd "apps/integration_openproject"
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

elif [[ "$INTEGRATION_APP_SETUP_METHOD" == "sso-external" ]]; then
    echo "[INFO] Waiting for Keycloak to be ready..."
    wait_for_server "https://$KEYCLOAK_HOST"
    echo "[INFO] Keycloak is ready."

    curl -s https://raw.githubusercontent.com/nextcloud/integration_openproject/master/integration_oidc_setup.sh -o integration_oidc_setup.sh

    NC_HOST=https://$VIRTUAL_HOST \
        NC_ADMIN_USERNAME=admin \
        NC_ADMIN_PASSWORD=admin \
        NC_INTEGRATION_PROVIDER_TYPE=external \
        NC_INTEGRATION_PROVIDER_NAME=$OIDC_KEYCLOAK_PROVIDER_NAME \
        NC_INTEGRATION_OP_CLIENT_ID=$OIDC_KEYCLOAK_OPENPROJECT_CLIENT_ID \
        NC_INTEGRATION_TOKEN_EXCHANGE=true \
        NC_INTEGRATION_ENABLE_NAVIGATION=false \
        NC_INTEGRATION_ENABLE_SEARCH=false \
        OP_HOST=https://$OPENPROJECT_HOST \
        OP_ADMIN_USERNAME=admin \
        OP_ADMIN_PASSWORD=admin \
        OP_STORAGE_NAME=nextcloud \
        OP_STORAGE_AUDIENCE=nextcloud \
        bash integration_oidc_setup.sh
fi
