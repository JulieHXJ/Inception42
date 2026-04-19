#!/bin/bash

mkdir -p /run/mysqld 
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql-install-db --user=mysql --datadir=/var/lib/mysql
fi

service mariadb start
sleep 5

mariadb -u root --socket=/run/mysqld/mysqld.sock << EOF
CREATE DATABASE IF NOT EXISTS ...
CREATE USER IF NOT EXISTS ...
GRANT ALL PRIVILEGES ...
ALTER USER 'root'@'localhost' IDENTIFIED BY ...
FLUSH PRIVILEGES;
EOF

mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown

exec mysqld --user=mysql
