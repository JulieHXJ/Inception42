#!/bin/bash
set -e

MYSQL_PASSWORD="$(cat /run/secrets/mysql_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_password)"

mkdir -p /run/php
mkdir -p /var/www/html

cd /var/www/html

echo "Waiting for MariaDB to be ready..."
until mariadb \
    -h mariadb \
    -u "${MYSQL_USER}" \
    -p"${MYSQL_PASSWORD}" \
    -e "SHOW DATABASES;" \
    > /dev/null 2>&1
do
	echo "MariaDB is not ready yet. Retrying in 2 seconds..."
	sleep 2
done
echo "MariaDB is ready to accept SQL."

# install WordPress and configure db
if [ ! -f /var/www/html/wp-config.php ]; then

    wp core download \
        --allow-root \
        --force

    wp config create \
        --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306"

fi

# connect to mariadb and create admin user
if ! wp core is-installed --allow-root; then

    wp core install \
        --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"

fi

# Create a new user as editor if not exists
if ! wp user get "${WP_USER}" --allow-root > /dev/null 2>&1; then

    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --allow-root \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=editor

fi

chown -R www-data:www-data /var/www/html

exec /usr/sbin/php-fpm7.4 -F