# a script describing how to build an image.

FROM alpine:3.19

# install packages, configure stuff
RUN apk add --no-cache nginx

# copy config files or scripts into image
# COPY ./nginx.conf /etc/nginx/nginx.conf

CMD [ "nginx", "-g", "daemon off;" ]