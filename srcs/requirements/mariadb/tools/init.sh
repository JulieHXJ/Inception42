#!/bin/bash
set -e # Exit process on any error

# read secrets from files
MYSQL_PASSWORD="$(cat /run/secrets/mysql_password)"
MYSQL_ROOT_PASSWORD="$(cat /run/secrets/mysql_root_password)"

mkdir -p /run/mysqld 
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

# first time init db
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql-install-db --user=mysql --datadir=/var/lib/mysql
fi


service mariadb start

# wait for MariaDB to be ready
until mariadb-admin ping --silent; do
    sleep 1
done

mariadb -u root << EOF
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

mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown

exec mysqld --user=mysql
