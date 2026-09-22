FROM debian:bullseye

RUN apt-get update \
    && apt-get install -y nginx openssl \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default

COPY ./conf/default.conf /etc/nginx/conf.d/default.conf
COPY ./tools/setup.sh /setup.sh

RUN chmod +x /setup.sh

EXPOSE 443

CMD ["/setup.sh"]
