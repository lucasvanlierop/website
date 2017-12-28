    ---
draft: true
title: Running (Linux) containers with immutable file systems in Docker Compose, Docker Swarm & Kubernetes. 
categories: 
    - software-development
tags: 
    - docker
    - docker-compose
    - docker-festival
    - immutability
    - kubernetes
    - security
---

Target audience: developers who (are planning to) run containers in production.

TL;DR Run your containers with an immutable file system, its more secure and predictable!

---
<span class="header-image">![Just a random picture of a locked door](/images/blog/software/locked-door.jpg)</span>
## What are the advantages of a container with an immutable file system? 

Because of predictability! When any kind of change is applied to a running system there's always a chance that besides fixing a bug or adding a feature something else unexpectedly breaks.

But let's look ad some disadvantages of various deployment strategies first:

Over the years development and deployment strategies of (web) applications have evolved a lot. 
Each evolution made the process a bit more more predictable and secure but still had some disadvantages.


In the old days developers used to edit files directly on servers or synced them from a development machine using SFTP, Rsync etc. 
There was no real separation between development and deployment at all. 
There were no guarantees on:

- <i class="fa fa-times" style="color: red"></i> which code was deployed
- <i class="fa fa-times" style="color: red"></i> deployed code has been verified to work as expected
- <i class="fa fa-times" style="color: red"></i> deployed code is fully compatible with the stack it runs on.
- <i class="fa fa-times" style="color: red"></i> deployed code is has not been tampered with

After a while version control systems were used and code was deployed by checking out the latest version on a server.
This at least provided guarantees on:

- <i class="fa fa-check-square" style="color: green"></i> which code was deployed

Then fully automatic pipelines that could build and test applications before deploying them became more common.
This provides guarantees on:
 
- <i class="fa fa-check-square" style="color: green"></i> which code was deployed
- <i class="fa fa-check-square" style="color: green"></i> deployed code has been verified to work as expected
 
Now with the arrival of container technologies it's possible to go one step further and package the application, 
its runtime and all of its dependencies into one deployable artifact a.k.a. a container image.
This allows testing the entire stack in a build pipeline and gives us many guarantees (but not all)

- <i class="fa fa-check-square" style="color: green"></i> which code was deployed
- <i class="fa fa-check-square" style="color: green"></i> deployed code has been verified to work as expected
- <i class="fa fa-check-square" style="color: green"></i> deployed code is fully compatible with the stack it runs on.

While this is great there's still one issue. What if something in the container changes after it has been deployed?
Changes to a running container can happen either by accident or as part of a hacking attempt. 
Whatever the cause if something is changed, the guarantees we had earlier are lost. 

The good news is that this can be prevented fairly easy by just starting the container with an immutable (read only) file system. 
In practice this means your application, its configuration and basically everything else that's in the container can NOT be changed.

- <i class="fa fa-check-square" style="color: green"></i> which code was deployed
- <i class="fa fa-check-square" style="color: green"></i> deployed code has been verified to work as expected
- <i class="fa fa-check-square" style="color: green"></i> deployed code is fully compatible with the stack it runs on.
- <i class="fa fa-check-square" style="color: green"></i> deployed code has not been tampered with

Since many containerized projects do not make use of immutable containers yet I'd like to share some examples on how this can be configured in some of the common orchestration tools. 

## Example #1 Configuring immutable containers in Docker Compose (version 3) and Docker Swarm

With Docker all you have to do is mark the service as 'read only'.

*Note that this example is for version 3 of the Docker Compose file format which can also be used for deploying to Docker Swarm. 
For the 'classic' Docker Compose version 2 format check the example below.*


```yaml
version: '3'

services:
  app:
    ...
    read_only: true
```

The example above assumes the application does not require any changes to the file system. 
In practice that might not always be possible because some processes require some files or directories to be writable.
For example a temporary directory for storing file uploads might be necessary. 
Of course the final uploaded files should be stored in a persistent volume. 
Another example might be processes like Apache HTTP server that want to store their process id in a [`pid` file](https://linux.die.net/man/3/pidfile).

This could be solved by mounting a writable file or directory from the local file system into the container. 
However since there's no need to persist these files they can be written to memory instead of disk.
 
Docker Compose supports temporary volumes in memory.
In this example a writable directory named `/var/run` will be available in the container.  

```yaml
version: '3'

volumes:
  apache-run:
    driver: local
    driver_opts:
      type: tmpfs
      device: tmpfs
      
services:
  app:
    ...
    read_only: true
    volumes:
      - apache-run:/var/run
```

## Example #2 Configuring immutable containers in the classic Docker Compose version 2 format

The Docker Compose version `2` file format is a bit different and has a separate `tmpfs` configuration that creates a temporary volume in memory.

*Note you have to specify at least the `uid` (user id) that should own the volume (unless the process runs as root which is not recommended for security reasons!).*  


```yaml
version: "2"

app:
    read_only: true
     tmpfs:
        - /var/run:uid={uid-of-the-process}
```

## Example #3 Configuring immutable file systems in Kubernetes (v1.7+)

In Kubernetes an immutable file system can be configured as part of a deployment security context. 
Instead of Docker's tmpfs a volume of the type `emptyDir` must be configured.

```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
...
spec:
  ...
  template:
    ...
    spec:
      containers:
      - name: app
        ...
        securityContext:
          readOnlyRootFilesystem: true
        volumeMounts:
          - mountPath: /var/run
            name: apache-run
      volumes:
      - name: apache-run
        emptyDir: {}

```

## Rounding up

- *Should development containers have an immutable file system too?*
Not necessarily since it's a mainly security measure for production situations.
However it's better to have a similar setup across all environments so possible issues can be spotted before going to production. 

- *Do all containers need to have an immutable file system?*
In general I would recommend to at least make containers where scripts/applications should be immutable. So web and application servers and maybe even database servers.
And yes: unexpected code execution should not be possible at all, query parameters should be escaped etc. 
but as with all security measures it's [Defense in depth](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) that makes a system more secure.

*FYI: The examples above are taken from a legacy WordPress project. Since I'm not a WordPress expert at all I intentionally run it in an immutable container to reduce the attack vector and 
to prevent unplanned automatic updates from happening. For some more context check the full Docker Compose config at the time of writing for both 
[development](https://github.com/allihoppa/allihoppa.nl/blob/4e061496f8d489a00c0d1cf32725d90e376eb426/environment/dev/docker-compose.yml#L28) and
[production](https://github.com/allihoppa/allihoppa.nl/blob/4e061496f8d489a00c0d1cf32725d90e376eb426/environment/prod/docker-compose.yml#L43)*

---

*Thanks 
[Jeroen](https://twitter.com/n0x13),
[Annelies](https://twitter.com/alli_hoppa) and
[Caroline](https://twitter.com/erzitkaktussen)
for reviewing this post*

