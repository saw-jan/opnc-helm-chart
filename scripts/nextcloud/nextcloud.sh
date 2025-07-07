#!/bin/bash

set -eo pipefail

rm -f /etc/ssl/certs/OPNC_Root_CA.pem /usr/local/share/ca-certificates/OPNC_Root_CA.crt
cp /certs/ca.crt /usr/local/share/ca-certificates/OPNC_Root_CA.crt
update-ca-certificates

WEB_ROOT="/var/www/html"
echo "Setting up Nextcloud server..."

rm -rf /tmp/server || true
# get nextcloud server
git clone --single-branch -b "${SERVER_BRANCH}" --depth 1 https://github.com/nextcloud/server.git /tmp/server
# get viewer app
git clone --single-branch -b "${SERVER_BRANCH}" --depth 1 https://github.com/nextcloud/viewer.git /tmp/server/apps/viewer
git config -f .gitmodules submodule.3rdparty.shallow true
(cd /tmp/server && git submodule update --init)
# sync server files to the web root
rsync -a --chmod=755 --chown=www-data:www-data /tmp/server/ $WEB_ROOT
# fix permissions
chown www-data: -R $WEB_ROOT/data
chown www-data: $WEB_ROOT/.htaccess

# patch bootstrap script
# disable demo users creation
sed -i "s/^configure_add_user() {/configure_add_user() {\n\texit 0/" /usr/local/bin/bootstrap.sh

# run the nextcloud setup
/usr/local/bin/bootstrap.sh apache2-foreground
