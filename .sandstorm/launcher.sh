#!/bin/bash
mkdir -p /var/lib
test -d /var/lib/mysql || cp -r /opt/app/.sandstorm/mysql /var/lib

test -f /var/feed-icons || cp -r /opt/app/feed-icons.orig /var/feed-icons
test -f /var/cache || cp -r /opt/app/cache /var
rm -rf /var/lock
mkdir -p /var/lock
mkdir -p /var/lib/php5/sessions

# Create a bunch of folders under the clean /var that php, nginx, and mysql expect to exist
mkdir -p /var/lib/mysql
mkdir -p /var/lib/nginx
mkdir -p /var/log
mkdir -p /var/log/mysql
mkdir -p /var/log/nginx
# Wipe /var/run, since pidfiles and socket files from previous launches should go away
# TODO someday: I'd prefer a tmpfs for these.
rm -rf /var/run
mkdir -p /var/run
mkdir -p /var/run/mysqld

# Ensure mysql tables created
HOME=/etc/mysql /usr/bin/mysql_install_db --force

# Spawn mysqld, php
HOME=/etc/mysql /usr/sbin/mysqld &
/usr/sbin/php5-fpm --nodaemonize --fpm-config /etc/php5/fpm/php-fpm.conf &
# Wait until mysql and php have bound their sockets, indicating readiness
while [ ! -e /var/run/mysqld/mysqld.sock ] ; do
    echo "waiting for mysql to be available at /var/run/mysqld/mysqld.sock"
    sleep .2
done
while [ ! -e /var/run/php5-fpm.sock ] ; do
    echo "waiting for php5-fpm to be available at /var/run/php5-fpm.sock"
    sleep .2
done

# run update every 30 min, and pause 20s before the first run (to give time for server to start)
bash -c 'cd /opt/app; sleep 20; while true; do /usr/bin/php5 /opt/app/update.php --feeds --force-update; sleep 1800; done' 2>&1 &

# Start nginx.
/usr/sbin/nginx -g "daemon off;"
