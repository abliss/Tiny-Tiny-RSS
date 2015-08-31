#!/bin/bash
# Checks if there's a composer.json, and if so, installs/runs composer.

set -euo pipefail

cd /opt/app

if [ -f /opt/app/composer.json ] ; then
    if [ ! -f composer.phar ] ; then
        curl -sS https://getcomposer.org/installer | php
    fi
    php composer.phar install
fi

test -e feed-icons.orig || mv feed-icons feed-icons.orig

cd /opt/app/sandstorm
make
sudo cp bin/sandstorm-httpGet /usr/bin
