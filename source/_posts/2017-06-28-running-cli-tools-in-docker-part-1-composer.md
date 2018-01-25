---
title: Running CLI tools In Docker Part 1; Composer
categories: 
    software-development
tags: 
    - docker
    - docker-festival
---

_This article is part of a [series of blog posts](/blog/tags/docker-festival/) related to the 
[Docker Festival](https://twitter.com/hashtag/dockerfestival?src=hash) workshop
[Matthias Noback](https://twitter.com/matthiasnoback) and I did at
[Dutch PHP Conference 2017](https://www.phpconference.nl/)_

## When your (web) application runs in a container but tools still run on your host

I've encountered 'hybrid' combinations where people run their (web) applications in a container but still run tools directly on their host.

There are however good reasons to run all tools in a container too:

- It guarantees the tools run on the __exact same software__ as the application itself.
- It guarantees all users of the use the __exact same software__
- It does __not require installing extra software__ on your host

In this post the [PHP package manager Composer](https://getcomposer.org/) will be taken as an example on how to run a CLI tool in a container.
Composer was chosen since I have used it for almost every project the last 5 years.
Furthermore since it has quite a few requirements which makes it an interesting case.

## There are a few things you need to understand about running processes in Docker.

### Processes in Docker run as root by default!
If that does not ring a bell yet: It's advisable to run processes as a non-root user especially when they generate files.

__This might sound like a contradiction but by default a user would create files that are NOT owned by that user! It would even require sudo rights to remove those files.__

### Some processes [can't be stopped](https://www.youtube.com/watch?v=lP4Nnek6DCo)
The first process that is started in Docker is considered (by Linux) the [init](https://en.wikipedia.org/wiki/Init) process.
Linux is designed to keep that process running whatever happens.
The only way to stop that process (aside from letting Docker `kill` that container) is to let the process itself listen to so called ['signals'](https://en.wikipedia.org/wiki/Unix_signal).

Most non 'server' processes are not designed to handle signals properly.
In practice this means that you can't stop a process once you've started it.

This can be resolved by:

- Declaring a [`STOPSIGNAL`](https://docs.docker.com/engine/reference/builder/#stopsignal) in your `Dockerfile`
- Using an init process such as [Tini](https://github.com/krallin/tini)
- Wrapping the command in a [bash `trap`](http://redsymbol.net/articles/bash-exit-traps/)

I have personally used Tini a lot since that also solved the [Zombie reaper problem](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/). 
If I remember correctly this problem has been solved by now.

### (Most) processes expect configuration 
Most processes expect some form of configuration either in the form of files or environment variables.
By default processes running in a container do not have access to anything outside the container either fail or behave different than expected.

Composer for example expects a `.composer` dir to be present in the home dir (which you can specify).
Since this directory not only contains configuration but also cache files there's an enormous speed benefit in 'reusing' that dir for the container.

### Some processes expect devices to be present
Just like variables of file systems (almost) no devices are shared with the container. 

In the case of Composer chances are it expects a SSH socket to be present.
As mentioned earlier it's very likely Composer has to download some GIT repositories which is often done via SSH. 

That's a bit of a problem since that would sharing the SSH socket with the container.
While that's possible it's a bit more work.
Also sharing power of SSH with an isolated process which only needs a access a limited set of resources does not fit the 'least access principle' of containerized processes.

An easier approach in many cases is to use HTTP(S) instead. 
In case access to private repositories is required make sure an access token is set up:

For GitHub this can be done like:
```bash
composer config -g github-oauth.github.com <oauthtoken>
```

See also the [Composer docs on this](https://getcomposer.org/doc/articles/troubleshooting.md#api-rate-limit-and-oauth-tokens)

For GitLab this can be done like:   
```bash
composer config your.gitlab.domain <user> <token>
```

## Now lets's containerize Composer

With that out of the way let's see what is required to run Composer in a container

### Install

First install Composer itself. 
Since most of the dependencies Composer is likely to install are either in zip or git 'format' support for both is required too.

```dockerfile
# Note this assumes you have already create a base image for you application containing
# PHP and all required libraries.
# In this case the base image is expected to be based on Alpine Linux.
FROM your/application:base 

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

# Run tini as init process    
ENTRYPOINT ["/sbin/tini", "--"]    
```

### Configure

Then share the required configuration (in `docker-compose` format). 
The following configuration will cause composer to:

- Run as a normal user (it's possible to automate by exporting these values using the `id` program)
- Look for it's configuration in /home/.composer
- Run all commands in the project dir that has been shared with the container

_Note: I left out all the usual stuff_

```yaml
services:
  app:
    ...
    user: user-id:group-id
    working_dir: /your-project-dir
    environment:
      HOME: /home
    volumes:
      - ./:/your-project-dir
      - ~/.composer:/home/.composer
```

### Run

Now it's time to run the process.
To prevent having to use docker commands all the time it's nice to have a wrapper script.
The example below runs composer and passes all scripts arguments on to composer.
 
```bash
#!/usr/bin/env bash
docker-compose run --rm app composer "$@"
```
 
You could run the above like for example:

```bash
./composer install --ansi --no-dev --optimize-autoloader
```

## Protip: Add platform requirements 
Since compose now runs on the same stack (Composer calls it 'platform') as the application it's possible to add specific requirements of the stack itself 
without the risk of false positives or negatives.
For example you can require a specific PHP version or extensions to be installed like:

```bash
./composer require "ext-zip" "*"
```

## Recap
Running CLI tools in Docker is pretty doable but you have to be aware of certain pitfalls.

I hope I have encouraged you to run your developer tools on the same stack your application runs on.
