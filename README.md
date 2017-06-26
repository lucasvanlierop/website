[![Build Status](https://travis-ci.org/lucasvanlierop/website.svg?branch=master)](https://travis-ci.org/lucasvanlierop/website)

#Website about my freelance developer activities.

This site uses [Sass](http://sass-lang.com/) for css and [Sculpin](https://sculpin.io/) for static site generation 
and runs in [Docker](docker.io). Images are pushed to [Docker Hub](https://hub.docker.com/r/lucasvanlierop/website/)

To develop:

- export your user id as `$HOST_UID`

- export your group id as `$HOST_GID`

- run: `docker-compose up`

To build and test run: `make test`

To just build run: `make`
