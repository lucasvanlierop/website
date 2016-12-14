FROM nginx:1.11-alpine

RUN rm -rf build /usr/share/nginx/html
COPY build /usr/share/nginx/html
COPY docker/app/nginx.conf /etc/nginx/nginx.conf
