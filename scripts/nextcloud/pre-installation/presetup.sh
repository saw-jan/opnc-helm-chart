#!/bin/bash

set -eo pipefail

if [[ -n "$NC_SERVE_GIT_BRANCH" ]]; then
    WEB_ROOT="/var/www/html"
    echo "Pulling Nextcloud server from github branch '${NC_SERVE_GIT_BRANCH}'..."

    rm -rf /tmp/server || true
    # get nextcloud server
    git clone --single-branch -b "${NC_SERVE_GIT_BRANCH}" --depth 1 https://github.com/nextcloud/server.git /tmp/server
    git config -f .gitmodules submodule.3rdparty.shallow true
    (cd /tmp/server && git submodule update --init)
    # sync server files to the web root
    rsync -a --chmod=755 --chown=www-data:www-data /tmp/server/ $WEB_ROOT
    # fix permissions
    chown www-data: -R $WEB_ROOT/data
    chown www-data: $WEB_ROOT/.htaccess
fi
