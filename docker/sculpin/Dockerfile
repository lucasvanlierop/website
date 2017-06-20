FROM php:7.1-alpine

RUN apk update \

# Install init system for running tasks as pid 1
    && apk add --no-cache tini \

# Install Composer + Git + Zip so it can fetch from various sources
    && apk add \
        --no-cache \
        git \
        zlib-dev \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && chmod +x composer.phar \
    && mv composer.phar /usr/local/bin/composer

RUN apk add \
    --no-cache \
    python

RUN apk add \
    --no-cache \
    py-pygments

# Cleanup
#    && rm -rf /var/cache/apk/*

ENTRYPOINT ["/sbin/tini", "--"]

