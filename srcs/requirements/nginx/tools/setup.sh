#!/bin/bash

mkdir -p /etc/nginx/ssl

openssl req -x509 -nodes -days 365 \
	-newkey rsa:2048 \
	-keyout /etc/nginx/ssl/inception.key \
	-out /etc/nginx/ssl/inception.crt \
	-subj "/C=DE/ST=BW/L=Heilbronn/O=42/OU=student/CN=xhuang.42.fr"

exec nginx -g "daemon off;"
