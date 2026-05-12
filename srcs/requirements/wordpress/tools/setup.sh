#!/bin/bash

mkdir -p /run/php
mkdir -p /var/www/html

cd /var/www/html

echo "Waiting for MariaDB to be ready..."
until mariadb -hmariadb -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SHOW DATABASES;" > /dev/null 2>&1; 
do
	echo "MariaDB is not ready yet. Retrying in 2 seconds..."
	sleep 2
done
echo "MariaDB is ready."

if [ ! -f /var/www/html/wp-config.php ]; then
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp

	wp core download --allow-root --force

	wp config create \
		--allow-root \
		--dbname=${MYSQL_DATABASE} \
		--dbuser=${MYSQL_USER} \
		--dbpass=${MYSQL_PASSWORD} \
		--dbhost=mariadb:3306

	wp core install \
		--allow-root \
		--url=${DOMAIN_NAME} \
		--title="${WP_TITLE}" \
		--admin_user=${WP_ADMIN_USER} \
		--admin_password=${WP_ADMIN_PASSWORD} \
		--admin_email=${WP_ADMIN_EMAIL}

	wp user create ${WP_USER} ${WP_USER_EMAIL} \
		--allow-root \
		--user_pass=${WP_USER_PASSWORD}
fi

exec /usr/sbin/php-fpm7.4 -F