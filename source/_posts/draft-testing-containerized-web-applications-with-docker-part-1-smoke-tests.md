---
draft: true
title: Testing containerized web applications with Docker part 1: Smoke tests
categories: 
    - software-development
tags: 
    - testing
    - docker
image: /images/blog/software/smoke-and-ashes.jpg
imageAlt: Smoke and ashes
---

_This article is part of a [series of blog posts](/blog/tags/docker-festival/) related to the 
[Docker Festival](https://twitter.com/hashtag/dockerfestival?src=hash) style of workshops
[Matthias Noback](https://twitter.com/matthiasnoback) are doing._

One of the great promises of containerized infrastructure is being able to run same stack (Operating system + runtime + application etc) in multiple environments.   
However it seems not everyone uses this to it's full potential.
 
- eyeopener, run app, not just test code but exact stack that will be deplo artefact
 verify what will be deployed
 
 
While it's fantastic to have (almost) no differences between development and production it's even better to have no differences between development, __CI__ and production.
Before the container era many CI environments were provisioned in a different way than development and production where tools like Ansible, Puppet etc. were used.

By far the biggest issue with tools like these is that are meant to update mutable infrastructure.
After a while both local (e.g. Vagrant based) development environments as well as production (like) environments are more or less up to date.
This means that provisioning almost never runs from scratch and breaking changes might be introduced without being noticed. 
Until a new server is added or a new employee joins the team that is.

I've seen many projects we're 
Because building a container image and starting it is a lot simpler than running a provisioning tool against a CI environment
it's now possible to not only run unit/integration tests but also real system tests.

This article will be an introduction to system testing a containerized application in a test/CI environment.   

## What is smoke testing?
Smoke testing is the most basic form of [system testing](https://en.wikipedia.org/wiki/System_testing).
Essentially it should be very simple tests that still cover a lot of the application and the stack it runs on.
When a smoke test fails there's something broken which should be fixed before doing further (system) testing.
 
What about the smoke?, well Wikipedia [explains system testing software](https://en.wikipedia.org/wiki/Smoke_testing) 
as "trying the major functions of software before carrying out formal testing".
The explanation for system testing electrical items is informative though: 
"looking for smoke when powering electrical items for the first time"

A small typo or misconfiguration can cause an entire (web) application to fail (even when all unit tests etc. have passed).
Many of these errors can be caught by testing something trivial as "can the homepage of the web application be accessed?" 

Since it's easy (and fast) to start containerized (web) applications in a test environment smoke testing might be more powerful than ever.

## Configuring the application to run in a CI

## Example #1, test if an application responds at all.

Since applications are started 'just in time' for testing
I've wrote earlier on how that raises challenges when trying to 
[proxy ingress traffic to web services](/blog/2017/06/25/accessing-your-docker-app-via-a-domain-name-using-traefik/).

Instead of dealing with specific container instances it's better to handle the processes as named services and use them that way

Another area where this raises challenges is when directly accessing the service (not a specific container), for example during testing. 
When running system tests against a web service, chances are the service hasn't finished starting yet or maybe it's waiting on another service.

Especially in a CI environment services are started just in time and most likely in the background. 
So how to determine if web service is ready for use?

## Polling

The simple answer is: poll it.
While event based systems are very nice, the easiest way by far to check if a web service is ready to handle requests is do a request.

A very simple tool which is available almost everywhere is: `curl`.
If it's called with the `--fail` argument it will fail (almost) silently on all server errors.
*(To make it completely silent also add the `--silent` argument)*

So as longs as `curl` requests keep failing the web service is not ready yet.

The following example tests a given url every 0.5 seconds:

```bash
#!/bin/sh

set -e

until test_output=`curl --silent --fail ${1}`; do
    echo "Waiting for the web service to become available ${1}"
    sleep 0.5;
done
```

## Make sure polling doesn't continue forever.

Of course it's always possible that something is broken and the service will never return a success status code.
To prevent the script from running forever it's advised let it time out after a while.

This can be done using the shell `timeout` function which can be prefixed to a command.
Assuming the poll script above can be found at `poll-web-service` an example of 'poll until timeout` looks like this:
    
```bash
timeout -t 60 poll-web-service {url-to-test}
```   

To prevent issues with different shell versions on different systems it's safer to run this in a container too.
The following example assumes there's a Docker Compose based setup with a (development) 
service named `app` and service named `web` which are in the same network.

```bash
docker-compose run --rm app sh -c 'timeout -t 60 poll-web-service http://web'
```

In a next article more advanced system tests will be covered 



