---
draft: true
title: Spliting your app in a back and front end service 
tags:
    - nginx
    - docker
    - php
categories:
    - software-development
---

Splitting an application into separate backend and front end services has the following advantages:
- Both services will be simpler since they have a single responsibility.
- Both services can be scaled individually

# Caveats

# Resolving backend from the frontend

While (at least in Docker Compose/Docker Swarm setups) services can be resolved by their name this doesn't always work out of the box.
External domain names seem to have precedence over internal service names.
Most of the time this is not a problem.
Until the name of a service is an existing top level domain like [`app`](https://icannwiki.org/.app).
Nginx will try to resolve `app` which results in a conflict.
This can be resolved by telling Nginx to use the [internal Docker DNS](https://docs.docker.com/engine/userguide/networking/configure-dns/).

An example is:



Docker service names 
TODO check this ^

Make sure frontend knows how determine which backend to use.

When nginx resolves it's upstream it doesn't use the Docker DNS by default.


