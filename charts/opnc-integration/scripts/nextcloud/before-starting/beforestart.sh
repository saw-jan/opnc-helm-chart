#!/bin/bash

set -eo pipefail

WORKING_DIR=$(pwd)
OCC=/var/www/html/occ

###################################
# Enable apps                     #
###################################
OLD_IFS=$IFS
# trim leading and trailing whitespaces
NEXTCLOUD_ENABLE_APPS=$(echo "$NEXTCLOUD_ENABLE_APPS" | xargs)
for app in $NEXTCLOUD_ENABLE_APPS; do
    IFS="@" read -r app_name app_version <<<"$app"
    IFS=$OLD_IFS

    APP_DIR="custom_apps/$app_name"

    $OCC app:disable "$app_name"
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

        curl -sL "${GIT_REPO_URL}/archive/refs/heads/${app_branch}.tar.gz" | tar -xz -C "$APP_DIR" --strip-components=1

        cd "$APP_DIR"
        composer install --no-dev
        npm ci && npm run dev
    else
        mkdir -p "$APP_DIR"
        # remove 'v' prefix if exists
        provided_app_version=$app_version
        app_version=${app_version#v}
        echo "[INFO] Enabling app '$app_name': $app_version"
        # https://github.com/nextcloud/integration_openproject/releases/download/v2.8.1/integration_openproject-2.8.1.tar.gz
        # e.g.: https://github.com/nextcloud-releases/user_oidc/releases/download/v7.2.0/user_oidc-v7.2.0.tar.gz
        RELEASE_ARCHIVE_URL="$GIT_REPO_URL/releases/download/v$app_version/$app_name-v$app_version.tar.gz"
        URL1=$RELEASE_ARCHIVE_URL
        if [[ $(curl -s -XHEAD -w "%{http_code}" "$RELEASE_ARCHIVE_URL") == 404 ]]; then
            # try without 'v' prefix
            # e.g.: https://github.com/nextcloud/integration_openproject/releases/download/v2.9.1/integration_openproject-2.9.1.tar.gz
            RELEASE_ARCHIVE_URL="$GIT_REPO_URL/releases/download/v$app_version/$app_name-$app_version.tar.gz"
            URL2=$RELEASE_ARCHIVE_URL
        fi
        if [[ $(curl -s -XHEAD -w "%{http_code}" "$RELEASE_ARCHIVE_URL") == 404 ]]; then
            # try without 'v' prefix
            # e.g.: https://github.com/H2CK/oidc/releases/download/1.8.1/oidc-1.8.1.tar.gz
            RELEASE_ARCHIVE_URL="$GIT_REPO_URL/releases/download/$app_version/$app_name-$app_version.tar.gz"
            URL3=$RELEASE_ARCHIVE_URL
        fi
        if [[ $(curl -s -XHEAD -w "%{http_code}" "$RELEASE_ARCHIVE_URL") == 404 ]]; then
            echo "[ERROR] App '$app_name' version '$provided_app_version' not found using the following:"
            echo -e "\t- $URL1"
            echo -e "\t- $URL2"
            echo -e "\t- $URL3"
            exit 1
        fi
        curl -sL "$RELEASE_ARCHIVE_URL" | tar -xz -C "$APP_DIR" --strip-components=1
    fi

    cd "$WORKING_DIR"
    # enable the app
    $OCC app:enable "$app_name"
done

# upgrade Nextcloud apps
$OCC upgrade
$OCC maintenance:mode --off

###################################
# Setup apps                      #
###################################
$OCC security:certificates:import /etc/ssl/certs/ca-certificates.crt
$OCC security:certificates:import "$SSL_CERT_FILE"
# allow local remote servers
$OCC config:system:set allow_local_remote_servers --value 1
# setup user_oidc app
$OCC config:app:set --value=1 user_oidc store_login_token
$OCC config:system:set user_oidc --type boolean --value="true" oidc_provider_bearer_validation
$OCC user_oidc:provider "$OIDC_KEYCLOAK_PROVIDER_NAME" \
    -c "$OIDC_KEYCLOAK_NEXTCLOUD_CLIENT_ID" \
    -s "$OIDC_KEYCLOAK_NEXTCLOUD_CLIENT_SECRET" \
    -d "$OIDC_KEYCLOAK_DISCOVERY_URL" \
    -o "openid profile email api_v3"
