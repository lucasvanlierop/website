FROM ruby:2.3-alpine

# Install Sass and dependencies
RUN apk add \
    --update \
    --no-cache \
    --virtual build-dependencies \
        ruby-dev \
        libffi-dev \
        build-base \
    && gem install \
        sass \
    && apk del build-dependencies

ENTRYPOINT ["sass"]
