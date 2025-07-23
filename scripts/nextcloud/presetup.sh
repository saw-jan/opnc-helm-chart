#!/bin/sh

# install git
apt update && apt install -y git

# install nodejs
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 20
ln -s $(which node) /usr/bin/node
ln -s $(which npm) /usr/bin/npm
ln -s $(which npx) /usr/bin/npx
ln -s $(which corepack) /usr/bin/corepack

# install composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/bin/composer

if [ -n "$NC_SERVE_GIT_BRANCH" ]; then
    WEB_ROOT="/var/www/html"
    echo "Pulling Nextcloud server from github branch '${NC_SERVE_GIT_BRANCH}'..."

    SRC_DIR=/tmp/server
    rm -rf $SRC_DIR || true
    mkdir -p $SRC_DIR
    # get nextcloud server
    git clone --single-branch -b "${NC_SERVE_GIT_BRANCH}" --depth 1 https://github.com/nextcloud/server.git $SRC_DIR
    cp -f $SRC_DIR/version.php /usr/src/nextcloud/version.php
    git config -f $SRC_DIR/.gitmodules submodule.3rdparty.shallow true
    cd "$SRC_DIR"
    git submodule update --init
    mkdir -p $SRC_DIR/custom_apps
    mkdir -p $SRC_DIR/data
    # npm ci
    # npm run build
    # # sync server files to the web root
    # rsync -a --delete --chmod=755 --chown=www-data:www-data $SRC_DIR/ $WEB_ROOT
    # # fix permissions
    # chown www-data: -R $WEB_ROOT/data $WEB_ROOT/custom_apps $WEB_ROOT/.htaccess
    # touch $SRC_DIR/synced
fi
