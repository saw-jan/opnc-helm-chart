#!/bin/sh

# install git
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt update && apt install -y git nodejs

# install composer
curl -s https://getcomposer.org/installer -o composer-setup.php
php composer-setup.php --install-dir=/usr/bin --filename=composer
rm composer-setup.php

if [ -n "$NC_SERVE_GIT_BRANCH" ]; then
    rm -f /usr/src/nextcloud/version.php
    curl -s "https://raw.githubusercontent.com/nextcloud/server/${NC_SERVE_GIT_BRANCH}/version.php" -o /usr/src/nextcloud/version.php
fi
