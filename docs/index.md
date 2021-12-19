# Project start

This page will be used to record the installation of a self-hosted devops environment.

The end-goal is to have an infrastructure running several services:
- [x] Setup docker and docker-compose
- [x] Web application powered by httpd
- [ ] Traefik to handle routing and load-balancing
- [ ] Node_exporter (for host metrics) and Cadvisor (for docker metrics) on each host
- [ ] Prometheus & Grafana for monitoring purpose

All these applications will be running inside dockers, as to be scalable in the future

It will start as a single host project and will slowly be turning into multiple-hosts

## Links

1. [Docker](https://github.com/maxime-lair/maxime-lair/blob/main/docs/index.md#docker)
	- [Pre-requisites](https://github.com/maxime-lair/maxime-lair/blob/main/docs/index.md#pre-requisites)
	- [Install docker engine](https://github.com/maxime-lair/maxime-lair/blob/main/docs/index.md#install-docker-engine)
	- [Test docker](https://github.com/maxime-lair/maxime-lair/blob/main/docs/index.md#test-docker)
	- [Post-install-shenanigan](https://github.com/maxime-lair/maxime-lair/blob/main/docs/index.md#post-install-shenanigan)
2. [httpd-web-server](https://github.com/maxime-lair/maxime-lair/blob/main/docs/index.md#httpd-web-server)
	- [Test-the-docker-image](https://github.com/maxime-lair/maxime-lair/blob/main/docs/index.md#test-the-docker-image)
	- [Docker-compose](https://github.com/maxime-lair/maxime-lair/blob/main/docs/index.md#docker-compose)
3. [traefik](https://github.com/maxime-lair/maxime-lair/blob/main/docs/index.md#traefik)
	- [Adding load balancer and reverse-proxy](https://github.com/maxime-lair/maxime-lair/blob/main/docs/index.md#Adding-load-balancer-and-reverse-proxy)
	- [Adding TLS and HTTPS](https://github.com/maxime-lair/maxime-lair/blob/main/docs/index.md#Adding-TLS-and-HTTPS)
4. Node_exporter & Cadvisor
5. Prometheus & Grafana

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

The Docker daemon binds to a Unix socket instead of a TCP port. By default that Unix socket is owned by the user root and other users can only access it using sudo. The Docker daemon always runs as the root user.

We do not want to preface the docker command with sudo, so we create a Unix group called docker and add users to it. When the Docker daemon starts, it creates a Unix socket accessible by members of the docker group.

### Dedicated user creation

We will create a user named **produser** for running docker, I simply added it with useradd and provided it with a password.

The group docker is created by default now, so we just have to add the new user to the group

```
$ sudo usermod -aG docker produser
```

### Test the new user

Now all we need to do is test creating a small docker container with this new user

We connect as produser

```
$ su produser
```

And we test a simple hello-world

```
$ docker run hello-world
```

It won't work as we previously stopped the docker daemon

We connect back on our sudo user and we enable the service (so It's available at next reboot) and start it

```
$ sudo systemctl enable docker.service
$ sudo systemctl start docker.service
$ sudo systemctl enable containerd.service
$ sudo systemctl start containerd.service
```

Then we connect back on our new user, and test its status

```
$ systemctl status containerd.service
● containerd.service - containerd container runtime
   Loaded: loaded (/usr/lib/systemd/system/containerd.service; enabled; vendor preset: disabled)
   Active: active (running)
     Docs: https://containerd.io
 Main PID: 84811 (containerd)
```

It's running well, we can try our hello-world

```
$ docker run hello-world

Hello from Docker!
This message shows that your installation appears to be working correctly.
```

It works, we can move on onto the next part, starting each docker container containing our different service (web, monitoring, proxy)

## Httpd web server

We want to deliver web pages through our server by hosting a docker container running a httpd process

We could use an alpine docker image, and add the web server onto it, but there is already an image available on the official website: https://hub.docker.com/_/httpd

To spice it up, we will try to scale the number of web servers, each running the same image, they will deliver the web server on the host on differents ports ranging from 35000 to 35100.
My objective at the end is to have redundancy, if the first one fails, we can always send them onto the second.

The web content we will deliver is the one available at https://github.com/maxime-lair/binsh

### Test the docker image

First, let's test the image provided. We do this to ensure any issues down-the-line would come from our HTML pages or docker configuration

We create a new repository, where we will work from, and ultimately have our web pages and docker configuration available at:
```
$ mkdir httpd-service
$ cd httpd-service
```

Then we can test our docker image:

```
$ docker run -dit --name my-apache-app -p 8080:80 -v "$PWD":/usr/local/apache2/htdocs/ httpd:2.4
Unable to find image 'httpd:2.4' locally
2.4: Pulling from library/httpd
e5ae68f74026: Pull complete 
bc36ee1127ec: Pull complete 
0e5b7b813c8c: Pull complete 
a343142ddd8a: Pull complete 
94c13707a187: Pull complete 
Digest: sha256:0c8dd1d9f90f0da8a29a25dcc092aed76b09a1c9e5e6e93c8db3903c8ce6ef29
Status: Downloaded newer image for httpd:2.4
478222b0c467cb72d244761c55a327750dd8edb5bb0bb33e9ac6972356ad4fe6
```

It started running, can we check the process and web page ?

```
$ docker ps
CONTAINER ID   IMAGE       COMMAND              CREATED              STATUS              PORTS                                   NAMES
478222b0c467   httpd:2.4   "httpd-foreground"   About a minute ago   Up About a minute   0.0.0.0:35000->80/tcp, :::35000->80/tcp   my-apache-app
$ curl http://localhost:35000
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
 <head>
  <title>Index of /</title>
 </head>
 <body>
<h1>Index of /</h1>
<ul></ul>
</body></html>
```

The image is running well, able to deliver our web pages onto the host, let's stop it and write our docker files now !

```
$ docker stop 478222b0c467
478222b0c467
$ docker ps                 
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```
### Docker compose

Since we want to start two web servers, let's use docker compose instead of two separate docker files

In order to [install it](https://docs.docker.com/compose/install/), we need to switch back to our sudo user

```
$ sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

We add execution rights on the binary

```
$ sudo chmod +x /usr/local/bin/docker-compose
```

Then we test it by switching back to **produser**

```
$ su produser
$ docker-compose --version
docker-compose version 1.29.2, build 5becea4c
```

**Note** We will not use any Dockerfile as we do not need to edit the image configuration.

Now we edit our docker-compose.yml file

```
$ cat docker-compose.yml
version: "3.9"
services:
        web:
                ports:
                        - "35000-35100:80"
                image: "httpd:2.4"
                volumes:
                        - ./binsh/:/usr/local/apache2/htdocs/
                networks:
                        - webzone
networks:
        webzone:
                driver: bridge
 ```
 
We indicate one service called **web** running on range 35000-35100 on the host and mapped to default httpd port (80)

Then we indicate the HTML files we want to use, and where to place them on the container

We could do it through a Dockerfile, but the advantage of using **volumes** is the live update, if we modify any files on /binsh/ on the host, we do not need to restart any docker container, as the changes will be effective immediately. If we did a COPY through a dockerfile, this would not be the case.

Now we retrieve the web files we want to host:
```
$ git clone git@github.com:maxime-lair/binsh.git
```

Advantage is : If I want to update my webfiles, I can leave the container running, and just re-do a git clone to have it available live.

Now we can start the docker-compose:

```
$ docker-compose up -d --scale web=10
Creating network "httpd-service_webzone" with driver "bridge"
WARNING: The "web" service specifies a port on the host. If multiple containers for this service are created on a single host, the port will clash.
Creating httpd-service_web_1  ... done
Creating httpd-service_web_2  ... done
Creating httpd-service_web_3  ... done
Creating httpd-service_web_4  ... done
Creating httpd-service_web_5  ... done
Creating httpd-service_web_6  ... done
Creating httpd-service_web_7  ... done
Creating httpd-service_web_8  ... done
Creating httpd-service_web_9  ... done
Creating httpd-service_web_10 ... done
```

We check on the host if we see our ports opened:
```
$ netstat -tlpn                                         
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:35025           0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:35026           0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:35027           0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:35028           0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:35029           0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:35030           0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:35031           0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:35032           0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:35033           0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:35034           0.0.0.0:*               LISTEN      -
```

Sure enough, our web servers are up and running, able to deliver the web pages on port 35xxx

We have some warnings at the web server start-up because we did not change the ServerName in the httpd configuration, as the process is unsure of the correct IP It is being hosted on. When we get our proxy running, we will be able to update this to our FQDN binsh.io

If you want to start your container in the background, you can add **-d** argument on the start

```
$ docker-compose up -d  
Starting httpd-service_web ... done
```

But as per the warning said, we are now running into an issue: how to load-balance any requests made to binsh.io on port 80 to the different container available on port 35xxx ? We could use nginx, but It isn't able to tell dynamically which ports/containers are up

Let's now move on to setting up a dynamic proxy solution: traefik

## Traefik

### Adding load balancer and reverse-proxy

From its website
> Traefik is a modern HTTP reverse proxy and load balancer that makes deploying microservices easy.
> Traefik integrates with your existing infrastructure components (Docker, Swarm mode, Kubernetes, Marathon, Consul, Etcd, Rancher, Amazon ECS, ...) and configures itself automatically and dynamically.

Traefik upgraded from V1 to V2 last year, and It's a bit difficult to understand how It now all works with services, endpoints, middlewares, etc.

Let's try it nonetheless

First, we create two configurations for traefik, a static configuration, which tells him what do we expose (where do we want requests to come in)
 
 **traefik.yml**
 ```
 ## traefik.yml

entryPoints:
        http:
                address: ":80"
        https:
                address: ":443"


# Docker configuration backend
providers:
  file:
          filename: dynamic_conf.yml
          watch: true
  docker:
          endpoint: "unix:///var/run/docker.sock"
          exposedByDefault: false

# API and dashboard configuration
api:
  insecure: true
 ```

We ask to listen on port 80 for http and https for 443, the usual.
Then we provide him a dynamic configuration file, that we will explain later, we want to keep watching this file in case of update so It can be applied live.
Then we tell him to listen for any new containers on the host, as we want to monitor/route onto them

Lastly, we expose the api, in an insecure way for now, we will add TLS/HTTPS later

We create our **dynamic_conf.yml** file

```
http:
    routers:
        http_router:
            rule: "Host(`binsh.io`)"
            service: web
    services:
        web:
            loadBalancer:
                servers:
                    - url: "http://httpd/
```

Here we provide a simple rule for routing: if we receive requests for our FQDN **binsh.io**, we load balance it on any servers responding to **httpd**

What is this httpd url then ? That's where trafik is nice, It will listen in the **docker-compose.yml** file (by listening on __/var/run/docker.sock__) and routes every request to binsh.io to these containers running a httpd web server. We do not need to indicate or even know the port, traefik will do it for us.

The **docker-compose.yml** file:
```
version: "3.9"
services:
        httpd:
                ports:
                        - "35000-35100:80"
                image: "httpd:2.4"
                volumes:
                        - ./binsh/:/usr/local/apache2/htdocs/
			- ./my-httpd.conf:/usr/local/apache2/conf/httpd.conf
                networks:
                        - webzone
        traefik:
                image: traefik:latest
                command: --api.insecure=true --providers.docker
                ports:
                        # The HTTP port
                        - "80:80"
                        # The Web UI (enabled by --api.insecure=true)
                        - "8080:8080"
                volumes:
                        # So that Traefik can listen to the Docker events
                        - /var/run/docker.sock:/var/run/docker.sock
                        - $PWD/traefik.yml:/etc/traefik/traefik.yml
                        - $PWD/dynamic_conf.yml:/dynamic_conf.yml
                networks:
                        - webzone
                        - proxy

networks:
        webzone:
                driver: bridge
                internal: true
        proxy:
                driver: bridge
```

A few changes to be noted:
- We added networks, so we can avoid exposing our dozens of possible web servers ports on the host, they will be in their own, secluded network **webzone**. Only traefik will be able to serve as bridge to the outside (to the host and beyond).
- We added traefik service, so It can run together with the httpd server.
- We added httpd configuration to change the servername to our FQDN

Now, we can start and scale our web servers depending on our needs

```
$ docker-compose up --scale httpd=3 -d
WARNING: The "httpd" service specifies a port on the host. If multiple containers for this service are created on a single host, the port will clash.
Starting httpd-service_httpd_1   ... done
Starting httpd-service_httpd_2   ... done
Starting httpd-service_httpd_3   ... done
Starting httpd-service_traefik_1 ... done
```
And we are now able to access our website from outside

![image](https://user-images.githubusercontent.com/72258375/146694753-a71ea54c-182b-47c8-a268-7a30494017e5.png)

Each GET is load balanced on the 3 different containers we just spawned.

Only the needed ports are opened on the host
```
$ netstat -tlpn
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name             
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      -      
```

We also have access to traefik dashboard on port 8080

![image](https://user-images.githubusercontent.com/72258375/146694799-44df59fa-1b25-4a0f-9582-e1d9c5725683.png)

### Adding TLS and HTTPS

Now that we have access on port 80, let's try to redirect on port 443 and handles everything more securely

**Under construction..**

## Node_exporter and Cadvisor


## Prometheus and Grafana




