FROM nginx:1.11-alpine

COPY docker/app/config/conf.d/default.conf /etc/nginx/conf.d/default.conf

RUN rm -rf /usr/share/nginx/html
COPY output_prod /usr/share/nginx/html

