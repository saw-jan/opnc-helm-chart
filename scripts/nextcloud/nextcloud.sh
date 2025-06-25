#!/bin/bash

set -e

rm -f /etc/ssl/certs/OPNC_Root_CA.pem /usr/local/share/ca-certificates/OPNC_Root_CA.crt
cp /certs/ca.crt /usr/local/share/ca-certificates/OPNC_Root_CA.crt
update-ca-certificates

echo "Setting up Nextcloud server..."

rm -rf /tmp/server || true
# clone nextcloud server
git clone -b "${SERVER_BRANCH}" --depth 1 https://github.com/nextcloud/server.git /tmp/server

(cd /tmp/server && git submodule update --init)
rsync -a --chmod=755 --chown=www-data:www-data /tmp/server/ /var/www/html
chown www-data: -R /var/www/html/data
chown www-data: /var/www/html/.htaccess
mkdir -p /var/www/html/custom_apps
chown www-data: -R /var/www/html/custom_apps

# run the nextcloud setup
/usr/local/bin/bootstrap.sh apache2-foreground
