---
title: Deploying Dockerized applications via an SSH tunnel.
categories: 
    software-development
tags: 
    - continuous-integration
    - continuous-deployment
    - docker
    - docker-festival
    - docker-swarm
image: /images/blog/software/tunnel.jpg
---

__Target audience:__ Developers who want to (continuously) deploy their Dockerized application.

*TL;DR: SSH can be used as an alternative to deploying Dockerized applications, this works best with Docker Swarm.*  
---

Many Docker projects start life as a Docker Compose based development setup. 
At a given moment these projects need to be deployed to production. 
This article will explain an alternative way deploying to a remote Docker server/cluster using the Docker socket and SSH instead of the Docker HTTP API.

## Why deploy Dockerized applications over SSH instead of directly via the API?
*Disclaimer this article doesn't say you MUST but you COULD deploy over SSH.*

Docker offers a secured API which can be used for deployments.
However... not everyone (or one's system administrator) wants to expose yet another port to the outside world.
Also the Docker API requires setting up some TLS certificates.
Docker has a tool named ['Machine'](https://docs.docker.com/machine/) that can manage those certificates however Machine comes with its own configuration which along with the certificates isn't very portable.

An alternative solution is to use the Docker socket and let 'come to you' over a secure connection that in most cases is already present: SSH. Or more specific: an SSH tunnel.
Since SSH supports public key authentication granting deployment access to a co-worker or CI server is just a matter of copying their public key to the server/cluster.

By using an [SSH tunnel](https://www.ssh.com/ssh/tunneling/) it's possible to 'trick' Docker by letting it think 
it's deploying to a local port which is actually a Docker socket on a remote system.

## But should I expose SSH at all?
<blockquote class="twitter-tweet" data-lang="nl"><p lang="en" dir="ltr">Don&#39;t install SSH in prod 😀😀 <a href="https://t.co/2pjAoWPhK6">https://t.co/2pjAoWPhK6</a></p>&mdash; David McKay (@rawkode) <a href="https://twitter.com/rawkode/status/943193815342571520?ref_src=twsrc%5Etfw">19 december 2017</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Well David has a fair point to consider. In this case I suggest NOT to use SSH to make changes to the server 
- [#immutabilityFTW](https://twitter.com/search?q=immutabilityFTW&src=typd) - 
but ONLY for deployments. 

## Prerequisites
- A server with [Docker installed](https://docs.docker.com/engine/installation/).
- A Docker Image registry like [Docker Hub](https://hub.docker.com/).
- A way to (preferably an automated CI pipeline) build Docker images and push them to the registry.
*(If you're unsure how to set this up, let me know in the comments. I might write an article about it!).*
- Knowledge of writing [Docker Compose v3 files](https://docs.docker.com/compose/compose-file/)

## What needs to be done to deploy Dockerized applications via SSH?
- Define which services should run e.g. in a (Docker stack deploy compatible) `docker-compose.yml` V3 file, which is probably similar to the development setup. 
- Define environment specific config either the `environment` section of a `docker-compose.yml` file or in a separate `*.env` file.
- Tell the server to start/update these services with the specified config.

## Why Docker Swarm should be used for production rather than Docker Compose
Earlier in this article Docker Swarm is mentioned a few times, why not use Docker Compose?
A common first approach to deploy application to a production server is to use Docker Compose since that is often the tool used during development.
While using Docker Compose for production is possible, Docker has a better alternative built in named: [Swarm](https://docs.docker.com/get-started/part4/).
Swarm - *from a deployment perspective* - works very similar to Docker Compose but has more advanced orchestration capabilities.

Compared to Docker Compose, Docker Swarm has the following advantages:

- It doesn't require installing Docker Compose on the server
- It doesn't require files like `docker-compose.yml`, `*.env` to be copied to the remote server
- It supports multiple servers for high availability (or just to provide more resources)
- It supports storing [secrets](https://docs.docker.com/engine/swarm/secrets/) for e.g. credentials that cannot be provided as an environment variable

Alternatively to Docker Swarm there are of course orchestrators like 
[Kubernetes](https://kubernetes.io/) 
or [DC/OS Marathon](https://mesosphere.com/blog/marathon-production-ready-containers/) 
but Docker Swarm still is the easiest production ready Docker orchestration tool to start with. 

So let's start!
 
## Step 1: preparing a server for use with Docker Swarm

To converting an existing Docker (1.13+) server into a Swarm node all that needs to be done is run the following command on the server:
```bash
docker swarm init
```

*Note: When a multi server ('node' in Docker Swarm speak) setup is desired a bit more is required -> read the [docs](https://docs.docker.com/get-started/part4/).*


*Note: if containers started by `docker(-compose)` are already running on the host the need to be stopped and restarted via `docker stack deploy`.*

## Step 2: setting up a tunnel to the Docker socket

As explained earlier the goal is to tunnel the remote Docker socket to the local system
There's one caveat though: this only works on SSHv6.7+ while most older OSes are stuck on SSHv6. 
However there's no need for updating since you can run an [SSH tunnel in Docker](https://hub.docker.com/r/kingsquare/tunnel/).

*Note: while it's possible to tunnel a remote __socket__ to a local __socket__ in this example the remote Docker __socket__ is tunneled to a locale __port__. 
This prevents having to deal with file permissions of the socket.*

```bash
DOCKER_TUNNEL_CONTAINER=docker_swarm_ssh_tunnel
DOCKER_TUNNEL_PORT=12374
DOCKER_SWARM_HOST={public-ip-or-hostname-of-a-swarm-master}
DEPLOY_USER={user-that-can-connect-via-ssh}

docker run \
    -d \
    --name ${DOCKER_TUNNEL_CONTAINER} \
    -p ${DOCKER_TUNNEL_PORT}:${DOCKER_TUNNEL_PORT} \
    -v ${SSH_AUTH_SOCK}:/ssh-agent \
    kingsquare/tunnel \
    *:${DOCKER_TUNNEL_PORT}:/var/run/docker.sock \
    ${DEPLOY_USER}@${DOCKER_SWARM_HOST}
```

*Note: Above setup is known to work on Debian like distros, 
Red Hat like distros do not seem to have a `SSH_AUTH_SOCK` environment variable. 
Suggestions to make this work on Red Hat like distros are welcome.* 

## Step 3: waiting until the tunnel is established
Now the tunnel has been started (in the background) any further commands should wait until it's actually usable.
An easy way to do that is to poll the tunnel by executing a simple docker command like `docker version`.
  
```bash
until docker -H localhost:${DOCKER_TUNNEL_PORT} version 2>/dev/null 1>/dev/null > /dev/null; do
 echo "Waiting for docker tunnel";
 sleep 1;
done
```

*Note: if the connection cannot be established for some reason the `until` loop will run forever.
If desired a [`timeout`](https://ss64.com/bash/timeout.html) can be added to stop the polling after a given amount of time.
This requires wrapping the loop in a separate bash script (or make target)*
 
## Step 4: deploying with `docker stack deploy`

Once a SSH tunnel has been established Docker can use it to deploy the stack to a remote Swarm node:

```bash
DOCKER_STACK_FILE={path/to/docker-compose.yml}
DOCKER_STACK_NAME={name-that-will-be-prefixed-to-each-server}

docker \
    -H localhost:${DOCKER_TUNNEL_PORT} \
    stack deploy \
    --with-registry-auth \
    -c ${DOCKER_STACK_FILE} \
    --prune \
    ${DOCKER_STACK_NAME}
```

## Step 5: closing the tunnel again
After the deploying has either succeeded or failed the tunnel should be closed again.

```bash
docker stop ${DOCKER_TUNNEL_CONTAINER}
docker rm ${DOCKER_TUNNEL_CONTAINER}
```

## A final overview of the total script 

*Note: this example is a simplified version of the deployment setup of [this website](https://lucasvanlierop.nl/) which relies heavily [GNU Make](https://www.gnu.org/software/make/manual/make.html) for orchestrating testing, building and deploying.
If you're not experience with GNU Make yet please give it a try, especially the [pre requisites](https://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html) are very powerful once you grasp the concept.*

```bash
#!/usr/bin/env bash

#...docker build, docker login, docker push etc. 

DOCKER_TUNNEL_CONTAINER=docker_swarm_ssh_tunnel
DOCKER_TUNNEL_PORT=12374
DOCKER_SWARM_HOST={public-ip-or-hostname-of-a-swarm-master}
DEPLOY_USER={user-that-can-connect-via-ssh}
DOCKER_STACK_FILE={path/to/docker-compose.yml}
DOCKER_STACK_NAME={name-that-will-be-prefixed-to-each-server}

docker run \
    -d \
    --name ${DOCKER_TUNNEL_CONTAINER} \
    -p ${DOCKER_TUNNEL_PORT}:${DOCKER_TUNNEL_PORT} \
    -v ${SSH_AUTH_SOCK}:/ssh-agent \
    kingsquare/tunnel \
    *:${DOCKER_TUNNEL_PORT}:/var/run/docker.sock \
    ${DEPLOY_USER}@${DOCKER_SWARM_HOST}

until docker -H localhost:${DOCKER_TUNNEL_PORT} version 2>/dev/null 1>/dev/null > /dev/null; do
    echo "Waiting for docker tunnel";
    sleep 1;
done

docker \
    -H localhost:${DOCKER_TUNNEL_PORT} \
    stack deploy \
    --with-registry-auth \
    -c ${DOCKER_STACK_FILE} \
    --prune \
    ${DOCKER_STACK_NAME}

docker stop ${DOCKER_TUNNEL_CONTAINER}
docker rm ${DOCKER_TUNNEL_CONTAINER}
```

Enjoy deploying your applications!

To see this in more context check [the deploy setup of this site at the time of writing this article](https://github.com/lucasvanlierop/website/blob/ed0483d5f6b12335a735da0e3d8b6859aacfe8f4/Makefile#L112)

---

*Thanks 
[Robin](https://twitter.com/fruitl00p) for creating this awesome [Docker SSH Tunnel image](https://hub.docker.com/r/kingsquare/tunnel/) 
and [Bram](https://twitter.com/Brammm) for triggering to finally write this article.*

*Thanks 
[Annelies](https://twitter.com/alli_hoppa) and
[Bram](https://twitter.com/Brammm)
for reviewing this post*
