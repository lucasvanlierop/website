---
draft: true
title: Continuous Docker (Swarm) deployment over SSH.
categories: 
    software-development
tags: 
    - ci
    - docker
    - docker-festival
    - docker-swarm
---

__Target audience:__ Developers who want to start with continuously deploying Docker applications.

TL;DR: Use Docker Swarm rather then Docker Compose for production, deploy via an SSH tunnel.

---

This article assumes the following:

- A server with [Docker installed](https://docs.docker.com/engine/installation/) is already available
- A CI server that automatically builds every commit (I might write an article about that sometime).

When above conditions are met continuous deployment with Docker basically comes to down to:
- Define which services should run e.g. in a `docker-compose.yml` file.
- Define environment specific config either in a `docker-compose.yml` file or in a separate `*.env` file.
- Tell the server to start/update these services with the specified config.

## Why Docker Swarm is better suited for deploying to production than Docker Compose. 

Many Docker projects start life as a Docker Compose based development setup. 
A common first approach to deploy the application to a production server is to use Docker Compose for that too.
And while that is possible Docker has a better alternative built in named: [Swarm](https://docs.docker.com/get-started/part4/)
which - *from a deployment perspective* - works very similar to Docker Compose but has more advanced orchestration capabilities.

Compared to Docker Compose, Docker Swarm has the following advantages:
- It doesn't require installing additional tools.
- It doesn't require files like `docker-compose.yml`, `*.env` to be copied to the remote server.
- It supports multiple servers for high availability (or just to provide more resources).

Alternatively to Docker Swarm there are of course orchestrators like 
[Kubernetes](https://kubernetes.io/) 
or [DC/OS Marathon](https://mesosphere.com/blog/marathon-production-ready-containers/) 
but Docker Swarm is still the easiest production ready Docker orchestration tool to start with.
 
## Step 1, preparing a server for use with Docker Swarm.

When a multi server ('node' in Docker Swarm speak) setup is desired a bit more is required (read the [docs]([Swarm](https://docs.docker.com/get-started/part4/))

But to converting an existing Docker (1.13+) server into a Swarm node all that needs to be done is run the following command on the server:
```bash
docker swarm init
```

*Note: if containers started by `docker(-compose)` are already running on the host the need to be stopped and restarted via `docker stack deploy`.*

## Step 2 Accessing the remote Docker API from a CI server
Docker has an HTTP API but not everyone (or their system administrator) wants to expose yet another port to the outside world.
Also the Docker API requires setting up TLS certificates.
Docker has a tool named ['Machine'](https://docs.docker.com/machine/) that can manage those certificates however Machine comes with it's own configuration which along with the certificates isn't very portable.

Another solution is to access the Docker socket over SSH. Since SSH suports public key authentication continuous deployment from a CI server only requires setting up one secret: the private key of a deploy user.
Instead it's possible to tunnel the port over SSH.

There's one gotcha though this only works on SSHv7+ while most older OSes are stuck on SSHv6. 
However there's no need for updating since you can run an [SSH tunnel in Docker]([Docker SSH Tunnel image](https://hub.docker.com/r/kingsquare/tunnel/)) too.

## Step 3 deploying with stack

## Step 3, forget about the API just use let the Docker socket come to you over SSH!
Use an SSH tunnel to the machine.

#But about passwords etc?
Secrets can be stored in [Docker Swarm secrets](https://docs.docker.com/engine/swarm/secrets/) rather than in files.

Below an example of how

...SHELL, docker login etc.

```makefile
DOCKER_TUNNEL_CONTAINER=DOCKER_SWARM_HOST_ssh_tunnel
DOCKER_TUNNEL_PORT=12374
DOCKER_SWARM_HOST=lucasvanlierop.nl
DOCKER_TUNNEL_USER=deploy
DOCKER_STACK_FILE=env/prod/docker-compose.yml
DOCKER_STACK_NAME=lucasvanlierop-website
.PHONY: deploy
.SILENT: deploy
deploy:
    # Create SSH tunnel to Docker Swarm cluster
    docker run \
        -d \
        --name $(DOCKER_TUNNEL_CONTAINER) \
        -p $(DOCKER_TUNNEL_PORT):$(DOCKER_TUNNEL_PORT) \
        -v $(SSH_AUTH_SOCK):/ssh-agent \
        kingsquare/tunnel \
        *:$(DOCKER_TUNNEL_PORT):/var/run/docker.sock \
        $(DOCKER_TUNNEL_USER)@$(DOCKER_SWARM_HOST)
    
    # Wait until tunnel is available
    until docker -H localhost:$(DOCKER_TUNNEL_PORT) version 2>/dev/null 1>/dev/null > /dev/null; do \
        echo "Waiting for docker tunnel"; \
        sleep 1; \
    done
    
    # Deploy
    docker \
        -H localhost:$(DOCKER_TUNNEL_PORT) \
        stack deploy \
        --with-registry-auth \
        -c $(DOCKER_STACK_FILE) \
        --prune \
        $(DOCKER_STACK_NAME)
    
    # Close tunnel
    docker stop $(DOCKER_TUNNEL_CONTAINER)
    docker rm $(DOCKER_TUNNEL_CONTAINER)
```


## But should I expose SSH?
<blockquote class="twitter-tweet" data-lang="nl"><p lang="en" dir="ltr">Don&#39;t install SSH in prod 😀😀 <a href="https://t.co/2pjAoWPhK6">https://t.co/2pjAoWPhK6</a></p>&mdash; David McKay (@rawkode) <a href="https://twitter.com/rawkode/status/943193815342571520?ref_src=twsrc%5Etfw">19 december 2017</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Well that's a fair point to think about, off course SSH gives way more than just the Docker API.
On the other hand if you don't use it to make changes to the server #immutabilityFTW and just for deployment I think it's ok.



- __NOTE:__ if you copy (parts of) above script make sure to convert SPACE to TABS since Make doesn't like spaces 
...- __NOTE:__ Above setup is known to work on Debian like distros, Red Hat like distros do not seem to have a `SSH_AUTH_SOCK` environment variable. If you know how 

To see this in more context check [the `Makefile` at the time of writing this article](https://github.com/lucasvanlierop/website/blob/2c549d0c94143b38fa96c9d4a972f073af889b8a/Makefile#L86)

---

Thanks 
[Robin](https://twitter.com/fruitl00p) for creating this awesome [Docker SSH Tunnel image](https://hub.docker.com/r/kingsquare/tunnel/) 
and [Bram](https://twitter.com/Brammm) for triggering to finally write this article.

