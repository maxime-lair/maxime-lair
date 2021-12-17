## Project start

This page will be used to record the installation of a self-hosted devops environment.

The end-goal is to have an infrastructure running several services:
- Prometheus & Grafana for monitoring purpose
- Node_exporter (for host metrics) and Cadvisor (for docker metrics) on each host
- Traefik to handle routing and load-balancing
- Web application powered by httpd

All these applications will be running inside dockers, as to be scalable in the future

It will start as a single host project and will slowly be turning into multiple-hosts

## First installation

# Docker

We need to install docker on each host, It has to be done through a sudo or root user as the final process will be running with root privileges (constraint of docker).

We follow the [instructions as per recommended](https://docs.docker.com/engine/install/centos/) to guide us through

We start off with the first docker installation

## Pre-requisites

First we check if docker is already installed, we do not want to install on top of an already available version.

Then, we add docker repository as It is not available natively on Centos

```Shell
docker 

sudo yum install -y yum-utils

sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

 ```

**Note** Since we are running it on Centos 8, It would have been nice to have used `dnf` instead of `yum` as the latter is getting deprecated.

## Install docker engine

Docker requires several tools to work, named **docker engine** and **containerd**

```
sudo yum install docker-ce docker-ce-cli containerd.io
```

It takes around 1m30 to complete.

## Test docker

Now we can start the docker engine and run a simple hello-world

```
$ sudo systemctl start docker                                                                               $ $ sudo docker run hello-world                                                                                   
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
2db29710123e: Pull complete 
Digest: sha256:cc15c5b292d8525effc0f89cb299f1804f3a725c8d05e158653a563f15e4f685
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash
```

We check a few commands to familiarize ourselves:
```
$ sudo docker images                                                                                           
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
hello-world   latest    feb5d9fea6a5   2 months ago   13.3kB

$ sudo docker container ls                                                                                     
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

Then we stop the service previously started
```
$ sudo systemctl stop docker                                                                                   
Warning: Stopping docker.service, but it can still be activated by:
  docker.socket
$ sudo systemctl stop docker.socket
 ```

**Note** It seems when starting docker, you start two units: service and socket. You have to manually stop them both as one could wake the other up if any request comes in. I have no idea why It is done this way, start and stop should be a one-liner command.

We stop the service because we might have more settings to adjust, and this is not the proper way to activate it anyway in the long run (we want to use **systemctl enable** to have it available at start-up).

## Post-install shenanigan

Work on this part (set up other user, etc)

https://docs.docker.com/engine/install/linux-postinstall/


