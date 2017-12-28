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

TL;DR Run your containers with an immutable file system, its more secure and predictable!

---

## Why should a container have an immutable file system? 

When any kind of change is applied to a running system there's always a chance that beside fixing a bug or adding a feature something else unexpectedly breaks. 
Over the years development and deployment strategies (web) applications have evolved a lot to prevent this from happening. 
Each evolution made the process a bit more more predictable and secure.

In the old days files were directly edited on a webserver or synced from a development machine using SFTP, RSYNC etc. 
This way there was no real separation between development and deployment at all.

After a while version control systems were used and code deployed by checking out the latest version on a server.
 
Then fully automatic pipelines that could build and test applications before deploying them became more common.
 
Now with the arrival of container technologies it's possible to go one step further and package the application, 
it's runtime and all of it's dependencies into one deployable artifact a.k.a. a container image.
This allows testing the entire stack in a build pipeline and gives us the following guarantees on:
- The fact that application AND the stack it runs on work
- What code EXACTLY will be deployed

While this is great there's still one issue. What if something in the container changes after it has been deployed?
Changes to a running container can happen either by accident or as part of a hacking attempt but whatever the cause. If that happens the guarantees we had earlier are lost. 

The good news is that this can be prevented fairly easy by just starting the container with an immutable (read only) file system. 
In practice this means your application, it's configuration and basically everything else that's in the container can NOT be changed.

Since many containerized projects do not make use of immutable containers yet I'd like to share some examples on how this can be configured in some of the common orchestration tools. 

## Example #1 Configuring immutable containers in Docker Compose (version 3) and Docker Swarm

With Docker all you have to do is mark the service as 'read only'.

*Note that this example is for version 3 of the Docker Compose file format which can also be used for deploying to Docker Swarm. 
For the 'classic' Docker Compose version 2 format check the example below*


```yaml
version: '3'

services:
  app:
    ...
    read_only: true
```

The example above assumes the application does not require any changes to the file system. 
In practice that might not always be possible because some processes require some files or directories to be writable.
For example a temporary directory for storing file uploads might be necessary for example. Of course the final uploaded files should be stored in a persistent volume. 
Another example might be processes like Apache HTTP server that to store it's process id in a [`pid` file](https://linux.die.net/man/3/pidfile).

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
Instead of Docker's tmpfs a volume of the type `emptyDir` must be configured.`

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
In general I would recommend to at least do it for any container where scripts/applications can be executed so web and application servers and maybe even database servers.
And yes: unexpected code execution should not be possible at all, query parameters should be escaped etc. 
but as with all security measures it's [Defense in depth](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) that makes a system more secure.

*FYI: The examples above are taken from a legacy WordPress project. Since I'm not a WordPress expert at all I intentionally run it in an immutable container to reduce the attack vector and 
to prevent unplanned automatic updates from happening. For some more context check the full Docker Compose config at the time of writing for both
- [development](https://github.com/allihoppa/allihoppa.nl/blob/4e061496f8d489a00c0d1cf32725d90e376eb426/environment/dev/docker-compose.yml#L28) and
- [production](https://github.com/allihoppa/allihoppa.nl/blob/4e061496f8d489a00c0d1cf32725d90e376eb426/environment/prod/docker-compose.yml#L43)*

