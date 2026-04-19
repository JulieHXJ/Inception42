FROM debian:bullseye

RUN apt-get update && apt-get install -y nginx openssl && rm -rf /var/lib/apt/lists/*

COPY ./conf/default.cnf /etc/nginx/conf.d/default.cnf
COPY ./tools/setup.sh /setup.sh

RUN chmod +x /setup.sh

EXPOSE 443

CMD ["/setup.sh"]
