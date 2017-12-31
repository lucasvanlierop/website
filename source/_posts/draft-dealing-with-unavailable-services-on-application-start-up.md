---
draft: true
title: Dealing with unavailable services on application start up
categories: 
    software-development
tags: 
    - docker
    - docker-festival
---

Containers are volatile, I've written before on how that creates issues when 
[proxying ingress traffic](/blog/2017/06/25/accessing-your-docker-app-via-a-domain-name-using-traefik/)
  
Another area where this is creating problems is when processes have (a chain of) dependencies on each other.

Many containerized applications are composed of multiple processes like for example a web server a run time a relational database, a key/value store. 
These processes will most likely have (a chain of) dependencies other services.

TODO: health check/parallelism


# Example 1, check if a web application is ready to serve requests

A database is a good example since it touches multiple issues like connections, state.

A simple dependency chain might look like this 

In development:
- In order to start the application it's database should be migrated to the latest state
- In order to execute database migrations vendor libraries must be installed
- In order to execute database migrations the database needs to be available
- In order to be available the database must be started.

In production:
- In order to add a newly deployed application to the pool it must be [healthy]
- In order for an application to be healthy it must be started.
- In order to start the application it's database should be migrated to the latest state
- In order to execute database migrations the database needs to be available


TODO: forward compatible migrations/config

/***

Note that if your happen to be using Doctrine ORM there's a caveat:
You need to installl vendor libraries with composer to execute DB polling
However composer install also triggers a clear cache script which in turn tries to generate proxies
for each database entity. This of course fails horribly when there's no database connection yet.
An easy solution is to have Doctrine generating proxies on demand.

In Symfony this can be configured as follows: 

```yaml
doctrine:
    orm:
        # This essentially allows CLI scripts to run when there is no database available (yet)
        # If disabled Doctrine will attempt to generate the proxy cache on cache warmup.
        auto_generate_proxy_classes: true
```

***/



Since all of these any of these can fail how do you make sure your application handles these correctly?

Let's solve the last problem first:

# Example 2: start a database when an application starts 
This is mainly about development/test environments where the database is also a containerized process whereas
in a production the database is most likely running as an external service.

I often use the [official Docker MySQL image](https://hub.docker.com/_/mysql/) for development and testing.
The easiest way to make sure the database is started when you run an application (or test suite!) 
depending is to use docker compose `depends_on` option. 
To trigger starting the database when the app starts configure something like: 
feature:

```yaml
version: "2"

services:
  app:
    ...
    depends_on:
      - db
  db:
    ...
```

# Example 2: Waiting until the database is ready
 
Starting a database might take some time, in most cases it takes longer than starting the application depending on it.
So how to determine when the database is ready? 
While I'm a fan of event driven systems. The easiest way to determine this is plain old polling.
A.k.a: just attempt to connect every second or so. 
This is preferably done using via the application database abstraction layer. 
This way one can be sure that not only the database is ready but also the application is correctly configured
to make a connection.

Since most of my applications are written in PHP and based on the Symfony framework 
I often use the [LIIP Monitor Bundle](https://github.com/liip/LiipMonitorBundle).
This library is able to check various kinds of pre conditions. 
Testing database connections is just one of the many things it can do.
There is probably a similar solution for your language/framework of choice.

`wait-for-services`

```bash
#!/usr/bin/env sh

DIR=`dirname $(readlink -f $0)`

until ${DIR}/console monitor:health --all; do
    >&2 echo "Waiting for all services to become available"
  sleep 1
done

```
