#!/bin/bash
set -e # Exit process on any error

# read secrets from files
MYSQL_PASSWORD="$(cat /run/secrets/mysql_password)"
MYSQL_ROOT_PASSWORD="$(cat /run/secrets/mysql_root_password)"

mkdir -p /run/mysqld 
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

# create mariadb storage
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql-install-db --user=mysql --datadir=/var/lib/mysql
fi

# init wp database and wp user
if [ ! -f "/var/lib/mysql/.mariadb_initialized" ]; then

    mariadbd \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --skip-networking &

    TEMP_PID=$!

    # wait for MariaDB to be ready
    until mariadb-admin \
        --protocol=socket \
        --socket=/run/mysqld/mysqld.sock \
        ping --silent
    do
        sleep 1
    done

    mariadb --protocol=socket --socket=/run/mysqld/mysqld.sock -u root << EOF

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%'
IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES
ON \`${MYSQL_DATABASE}\`.*
TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost'
IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

FLUSH PRIVILEGES;
EOF



    # shutdown
    mariadb-admin --protocol=socket --socket=/run/mysqld/mysqld.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

    wait "${TEMP_PID}"
    touch /var/lib/mysql/.mariadb_initialized # marker: only after SQL succeeds.


fi



exec mysqld --user=mysql --datadir=/var/lib/mysql
