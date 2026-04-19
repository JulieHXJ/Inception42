FROM debian:bullseye

RUN apt-get update && apt-get install -y \
	php7.4 php7.4-fpm php7.4-mysql mariadb-client curl \
	&& rm -rf /var/lib/apt/lists/*

COPY ./conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY ./tools/setup.sh /setup.sh

RUN chmod +x /setup.sh

EXPOSE 9000

CMD ["/setup.sh"]