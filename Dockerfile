FROM alpine:3.19

Run apk add --no-cache nginx

CMD [ "nginx", "-g", "daemon off;" ]