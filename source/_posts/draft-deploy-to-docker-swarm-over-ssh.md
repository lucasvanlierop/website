---
draft: true
title: Deploy to Docker Swarm over SSH
categories: 
    software-development
tags: 
    - ci
    - docker
    - docker-festival
    - docker-swarm
---

BRamm


## Why Docker Compose isn't ideal for deploying to production.
Many projects start life in a Docker Compose based development setup but a given moment they must be deployed to production.

Since Docker Compose isn't really meant for production usage, the closest option is Docker Swarm which is built in Docker for a while now.

While it's possible to use Docker Compose for production deployments its not ideal.  
For example some projects copy docker-compose config files (and everything they refer to) to the remote server.
Also Docker Compose  does not support multiple hosts which means if the application has to run on multiple servers it has to be deployed to every server.
Also if one server fails another server doesn't know about that and can't take over some of it's jobs even if it has enough
resources to do so.

Luckily Docker has a better option built in called Swarm which can achieve all of the above.
Since this article is mostly about how to deploy to a remote Swarm server/cluster I won't go imnto detail about Swarm itself.

## Accessing the remote Swarm
Docker Swarm (by default) uses a socket (`/var/run/docker`) to communicate with the Docker Engine.
Since this socket lives on a remote server and the Docker Client lives on a development or CI machine some form of communication has to be established.

## Accessing the remote Swarm via a port?
While Docker can run on a port too there's not really a need to configure that and to open firewall ports etc.
Instead it's possible to tunnel the port over SSH.

There's one gotcha though this only works on SSHv7+ while most older OSes are stuck on SSHv6. 
However there's no need for updating since you can run an [SSH tunnel in Docker]([Docker SSH Tunnel image](https://hub.docker.com/r/kingsquare/tunnel/)) too.

Below an example of how

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

__NOTE__ if you copy (parts of) above script make sure to convert SPACE to TABS since Make doesn't like spaces 


Thanks [Robin](https://twitter.com/fruitl00p) for creating this awesome [Docker SSH Tunnel image](https://hub.docker.com/r/kingsquare/tunnel/)

To see this in more context check [the `Makefile` at the time of writing this article](https://github.com/lucasvanlierop/website/blob/2c549d0c94143b38fa96c9d4a972f073af889b8a/Makefile#L86)
