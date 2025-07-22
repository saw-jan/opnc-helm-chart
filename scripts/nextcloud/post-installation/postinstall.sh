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
                echo -e "\tTry without the 'v' prefix in the version number."
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
    $OCC app:enable "$app_name"
done

# upgrade Nextcloud apps
$OCC upgrade

$OCC security:certificates:import /etc/ssl/certs/ca-certificates.crt
# setup user_oidc app
$OCC config:app:set --value=1 user_oidc store_login_token
$OCC config:system:set user_oidc --type boolean --value="true" oidc_provider_bearer_validation
$OCC user_oidc:provider "$OIDC_KEYCLOAK_PROVIDER_NAME" \
    -c "$OIDC_KEYCLOAK_NEXTCLOUD_CLIENT_ID" \
    -s "$OIDC_KEYCLOAK_NEXTCLOUD_CLIENT_SECRET" \
    -d "$OIDC_KEYCLOAK_DISCOVERY_URL" \
    -o "openid profile email api_v3"
