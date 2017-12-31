---
title: "Accessing your Docker app via a domain name using Træfɪk"
categories: 
    - software-development
tags: 
    - docker
    - docker-festival
    - traefik
---

_This article is part of a [series of blog posts](/blog/tags/docker-festival/) related to the 
[Docker Festival](https://twitter.com/hashtag/dockerfestival?src=hash) workshop
[Matthias Noback](https://twitter.com/matthiasnoback) and I did at
[Dutch PHP Conference 2017](https://www.phpconference.nl/)_

## Running a (read: just one) web application in Docker is easy.

So you're developing or running web applications in Docker but how do you expose them to the outside world?

When you have just one application the most common option when you're starting with Docker is to just bind a port to the host the container runs on like:

```bash
docker run -p 80:80 some/image
```

Now you can reach the application by `http://localhost`. 
That would work for development or even for production if you have just one web service per host.

## But what if you want more?

- You want run multiple web services?
- You want to run multiple instances of a service?
- You want to run services on multiple hosts?
- You just want a more descriptive hostname than 'http://localhost'?

## Reverse proxy to the rescue!

A very nice approach to these problems is to use a [reverse proxy](https://en.wikipedia.org/wiki/Proxy_server#Reverse_proxies). 
Reverse proxy servers have existed for ages, their job is to distribute incoming traffic (so called ingress) to application(s).

So you might have heard or even use [Nginx](https://nginx.org/) or [HAProxy](http://www.haproxy.org/) who have been serving the web for quite a while.

However since we're dealing with containers now there is one big difference: 
In comparison to 'classic' servers/virtual machines containers tend to be very volatile. 
Each time a service is deployed or scaled new containers come and old ones go.
The proxy needs to be able to keep track of all these changes which means it's not possible to rely on manual configuration.
Instead some automated reconfiguration is required. 

## Enter Træfɪk

[Træfɪk](https://traefik.io/) is an proxy that does just that.
It reconfigures itself continuously by listening to events on the system the containers are running on.
When using Docker (Swarm) it listens to the Docker socket (`/var/run/docker.sock`)

When a container is started it will be automatically be accesible via Træfɪk. 
When a container stops (either intended or unintended) it will be removed from the proxy config again.

You can now let Træfɪk listen to a given (number of) port number(s) like `80` or `443` and let it decided which traffic should go to which containers based on hostname. 
Containers as in plural? yes it does load balancing! It can also do SSL termination, maybe more on that later.
  
I can only say this is absolutely _awesome_.
I'm using it for quite a while now and I'm still wondering how I could work without it. 
And yes there are other products too but this is so simple yet so powerful.

## How does Træfɪk work?

So I said Træfɪk configures itself automatically?, Well almost. 
You have to add some configuration to your application to help Træfɪk understand how it should proxy requests to it.
To be able to do this you'll need to understand the basics of how Træfɪk works.
Træfɪk works with the concepts frontend and backend and makes sure traffic from a given frontend (accessible from the web) goes to a given backend (running on the orchestrator).

![Træfɪk architecture](images/blog/software/traefik-architecture.png)

_^Image is courtesy of traefik.io_

## Configuring Træfɪk
Træfɪk can be configured via labels, these labels can be set either as part of the container image or by an orchestration tool.
I prefer the latter since I like decoupling in general because it allows different settings for different environments.

At minimum Træfɪk needs to know the following things of your web application:

- To which backend it belongs
- On which domain it should be reachable from outside
- On which port it is running
- Via which network it can be reached

Furthermore I choose to explicitly enable services for Træfɪk.
This way Træfɪk is not bothered by containers I don't want to expose like backend applications and databases. 
Also this keeps the UI a lot cleaner.

Configuration is done by setting labels on the container.

A minimum configuration looks like this:

_Note 1: In the examples below I use `docker-compose` but Træfɪk supports many other systems too._

_Note 2: I left out all the usual stuff_

```yaml
version: '2'

networks:
  traefik:
    external:
      name: traefik_webgateway

services:
  app:
    ...
    networks:
      - traefik
    labels:
      - "traefik.enable=true"
      - "traefik.backend=lucasvanlierop-web"
      - "traefik.frontend.rule=Host:lucasvanlierop.nl.localhost"
      - "traefik.port=80"
      - "traefik.docker.network=traefik_webgateway"
```      

For a more complete example see the [`docker-compose.yml` of this site](https://github.com/lucasvanlierop/website/blob/e0f9d60bdfda1adbba7f41077df9870d57860688/docker-compose.yml)

_Note if you use Docker Compose files to deploy to a Docker Swarm Cluster the `labels` configuration goes under `deploy` rather than directly under the service._

```yaml
version: '3'

networks:
  traefik:
    external:
      name: traefik_webgateway

services:
  app:
    ...
    networks:
      - traefik
    deploy:
        labels:
          - "traefik.enable=true"
          - "traefik.backend=lucasvanlierop-web"
          - "traefik.frontend.rule=Host:lucasvanlierop.nl.localhost"
          - "traefik.port=80"
          - "traefik.docker.network=traefik_webgateway"
```

For the sake of completeness an example of how you could configure this directly in a `Dockerfile`
```dockerfile
LABEL "traefik.enable=true" \
    "traefik.backend=lucasvanlierop-web" \
    "traefik.frontend.rule=Host:lucasvanlierop.nl.localhost" \
    "traefik.port=80" \
    "traefik.docker.network=traefik_webgateway"
```

## Running Træfɪk
While Træfɪk itself is a Go binary you - off course - run it as a Docker container. 
There's even an [example Docker Compose configuration](https://docs.traefik.io/#docker).

Note that I prefer to explicitly enable services to be proxies by Træfɪk rather than having it autodetect all containers.
This can be achieved by running it with `--docker.exposedbydefault=false`.

For all other options: Træfɪk has pretty good [documentation](https://docs.traefik.io/)

## And now a quick look at the user interface

The user interface is pretty basic but shows the info you need about front and back ends, hosts, http protocols, load balancing protocols etc.

_Note it also has a tab where you can get some stats about application health but that's out of the scope of this article_

![Træfɪk services page](images/blog/software/traefik-services.png)

## And now try it yourself!

I hope Træfɪk will be as valuable to you as it is to me, let me know how it worked out for you!

If you want to need more, take a look at the [documentation](https://docs.traefik.io/). 

