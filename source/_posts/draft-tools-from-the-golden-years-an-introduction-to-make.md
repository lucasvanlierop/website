---
draft: true
title: Tools from the Golden Years, an introduction to (GNU) Make
categories: 
    software-development
tags: 
    - make
image: /images/blog/software/empowered-by-gnu.svg
---

One of the tools I use almost every day is (GNU) Make.

Since I will use Make in some of my following posts I'd thought I should give a very basic introduction.
This post is also meant to share my love for it and hopefully give you an incentive to try it.

If you find yourself creating cache directories, installing vendor libraries, compiling assets/artefacts, running tests, deploying using different scripts keep reading!

What I wanted was having to worry about only a very limited set of commands for all of the above. 
Most of them aren't things you need to execute directly but mostly a requirement of some other command.
Make is very good in glueing all kinds of scripts and their requirements together.


## But Make is very old, is it still useful?

Yes Make is very old. I was really surprised when I found out how old it really was, 
I knew it was from #backinthedays but [according to wikipedia](https://en.wikipedia.org/wiki/Make_(software))
it first occured in April 1976!
At the moment of writing that's exactly __42(!)__ years ago (and still going strong).

The seventies really were [the Golden Years](https://www.youtube.com/watch?v=JUuRGRcY9O0) of Unix 

a few years after [the dawn of time](https://en.wikipedia.org/wiki/Unix_time))!

## What does Make even do?
Make was (and still is) meant to compile C source files. 
However it can be used for many other applications too.
That said it's important to keep in mind it's original purpose.

What make does is running shell commands.
In case you wonder why would I need a tool to run shell commands if I already have a shell?

Well what makes make powerful is how it can orchestrate a (large) amount of separate calls in a specific order.

Especially with containers Make is a great fit since it's very good at abstracting the boiler plate of running containers.

# Use cases

In my Job was web application developer I have many use cases for Make, think of:

- Building Docker images
- Ensuring cache directories exist
- Installing vendor libraries (using PHP's Composer, Node's yarn)
- Running test & inspection tools (PHPunit etc.)
- Booting the application in development modus
- Creating dist(ribution) versions of the application
- Deploying the application

Even while most of these actions run in containers there are always difference between
host operating systems, mainly Linux and OSX in my case.
Make is capable of adapting to various environments in a simple but effective way: setting variables containing paths,
    command flags etc. 

## The anatomy of a Make target

A make goal consists of a target, optional pre-requisites and a rule

Where a target is a file that should be created.
    The pre-requisites are other files that should be created first in order to create the target
    The rule is a 
     
The are declared as follows:     

```makefile
a-target: a-pre-requisite
    a-rule
```

Alternatively it's also possible to run commands that do not result in a target.
These are called [Phony targets](https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html).
Phony targets can be used to run tests, clean actions etc.

```makefile
.PHONY: logs
logs:
    tail -f /var/log/some.log
```

## How I started using Make the wrong way
I intially started using Make as an alternative for Apache Ant 
which one of my previous employers used for running tests and generating deployable artefacts.
When I got into using (Docker) containers I Discovered GNU Make via [Jessie Frazelle](https://twitter.com/jessfraz)

While it's syntax is a bit quirky Make made so much more sense to me than the bulky XML files I was used to.
I started out with (ab)using Make as a dumb task runner like: (`PHONY` galore)

```makefile

.PHONY: do-something
do-something:
    shell-command
```

Using `.PHONY` is almost like a code smell to me now. 
In many cases it's better to use real target or [empty targets](https://www.gnu.org/software/make/manual/html_node/Empty-Targets.html)

## The power of dependency resolving.
Dependency (or pre-requisites as Make likes to call them) resolving might be the single most powerful feature of make.
...Make will create a graph of 

## Debugging
...--debug, silent


## Example

A very common scenrar


----------------------------- Next post

## Advanced, running things in parallel
Depending on the resources available Make can execute it's targets more efficiently by running them in parallel (using the `-j` argument)

```bash
make -j --output-sync=recurse target-1 target-2 (... target-n) 
```

The `--output-sync=recurse` buffers the output created by a given target until it has finished.
In most cases this is what you want because mixed output from multiple targets is pretty unreadble.



Make isn't really good in Idempotency
