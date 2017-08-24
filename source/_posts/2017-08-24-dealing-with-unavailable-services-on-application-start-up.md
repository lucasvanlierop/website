---
draft: true
title: Dealing with unavailable services on application start up
categories: 
    software-development
tags: 
    - docker
    - docker-festival
---

# the service dependency chain

Containers are volatile, I've written before on how that creates issues when [proxying ingress traffic]({ site_url}/blog/2017/06/25/accessing-your-docker-app-via-a-domain-name-using-traefik/)
  
Another area where this is creating problems is when processes have (a chain of) dependencies on each other.

Many containerized applications are composed of multiple processes like for example a web server a run time a relational database, a key/value store. 
These processes will most likely have (a chain of) dependencies other services.

A simple dependency chain might look like this:
- In order to start the application it's database should be migrated to the latest state
- In order to execute database migrations the database needs to be available
- In order to be available the database must be started.

Since all of these any of these can fail how do you make sure your application handles these correctly?

Let's solve the last problem first:

# Example 1: start a database when an application starts 
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
While I'm a fan of Event driven architectures. The easiest way to determine this is plain old polling.
Just attempt to connect every second or so. 
This is preferably done using via the application database abstraction layer. 
This way one can be sure that not only the database is ready but also the application is correctly configured
to make a connection.

Since most of my applications are written in PHP and based on the Symfony framework I often use the [LIIP Monitor Bundle](https://github.com/liip/LiipMonitorBundle).
There are probably many alternatives for other languages

`wait-for-services`

```bash
#!/usr/bin/env sh

DIR=`dirname $(readlink -f $0)`

until ${DIR}/console monitor:health --all; do
    >&2 echo "Waiting for all services to become available"
  sleep 1
done

```


Timeouts
