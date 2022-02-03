---
title: Docker introduction
author:
  name: Maxime Lair
  link: https://github.com/maxime-lair
date: 2021-12-26 18:00:00 +0000
categories: [ProjectBob, Infrastructure]
tags: [linux, docker, grafana, traefik, prometheus, httpd, node_exporter, cadvisor]
math: true
mermaid: true
---

This article is the first introduction to docker, and how to run containers on a single host.

The end-goal is to have an infrastructure running several services:
- [x] Setup docker and docker-compose
- [x] Web application powered by httpd
- [x] Traefik to handle routing and load-balancing
- [x] Prometheus & Grafana for monitoring purpose
- [ ] Node_exporter (for host metrics) and Cadvisor (for docker metrics) on each container

All these applications will be running inside dockers, as to be scalable in the future

It will start as a single host project and will slowly be turning into multiple-hosts

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

If you check httpd logs, we notice some warnings at the web server start-up because we did not change the ServerName in the httpd configuration, as the process is unsure of the correct IP It is being hosted on. When we get our proxy running, we will be able to update this to our FQDN binsh.io

If you want to start your container in the background, you can add **-d** argument on the start

```
$ docker-compose up -d  
Starting httpd-service_web ... done
```

But as for the docker warning, we now have an issue on our hands: how to load-balance any requests made to binsh.io on port 80 to the different web servers available on port 35xxx ? We could use Nginx, but we would have to manually update its configuration everytime we remove or add a container.

Let's try to use a new proxy solution called __Traefik__

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

Lastly, we expose the API, in an insecure way for now, we will add TLS/HTTPS later

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

What is this httpd url then ? Since they will be running on the same docker-compose, they will share the same default network. In this case, traefik container will be able to call up any httpd container by this url.

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

We create a file hosting our TLS certificates, and we need to review its file right (or we will get a slap on the wrist later when we start traefik)

```
$ touch acme.json
$ chmod 600 acme.json
```

This file will hold the TLS certificates created by __Let's encrypt__

First, we will secure our __docker-compose.yml__ by activating the secure api, removing the dashboard port, and sharing the acme.json file

We also added port 443 for HTTPS, since we will be redirecting all our traffic onto it. We want to be [HSTS](https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Strict_Transport_Security_Cheat_Sheet.html) approved !

```
$ cat docker-compose.yml 
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
                restart: unless-stopped
                command: --api --providers.docker
                ports:
                        # The HTTP port
                        - "80:80"
                        - "443:443"
                volumes:
                        # So that Traefik can listen to the Docker events
                        - /var/run/docker.sock:/var/run/docker.sock
                        - $PWD/traefik.yml:/etc/traefik/traefik.yml
                        - $PWD/dynamic_conf.yml:/dynamic_conf.yml
                        - $PWD/acme.json:/acme.json
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

Then we move onto our __traefik.yml__ file, we want 3 main points added:
- Redirect all HTTP trafic (port 80) to HTTPS (port 443)
- Secure the API (some kind of authentication required to access it)
- Add a certificate resolver - this will handled by Let's encrypt for validating TLS certificate (not expired, right domain, can be trusted, etc.)

```
$ cat traefik.yml 
## traefik.yml

entryPoints:
        http:
                address: ":80"
                http:
                        redirections:
                                entryPoint:
                                        to: https
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
        dashboard: true

certificatesResolvers:
        letsencrypt:
                acme:
                        email: <DEDICATED EMAIL ADDRESS>@gmail.com
                        storage: acme.json
                        httpChallenge:
                                entryPoint: http
```

**Note** You have to create a mail address to receive importants messages (expiration, etc.) when activating TLS, [see](https://letsencrypt.org/docs/expiration-emails/). For now this address is external, but we would want to have a self-hosted mail server with MX/SPF/DKIM/DMARC protection

Now, onto the interesting part, we have multiple things to do:
- Authenticate user trying to connect to Traefik API
- Route users onto the dashboard or onto the web server depending on their requests (since we removed port 8080)
- Make sure they are using HTTPS

This is all done through routers and middlewares on Traefik, routers will catch requests depending on their __rule__ to then direct them onto a list of __middlewares__ (which can authenticate, redirect, add headers, etc.), and if they managed to get through, route them onto a __service__

The logic will always be in Traefik-v2 : EntryPoints -> routers -> middlewares -> services -> providers

For authentication, we will use [BasicAuth](https://doc.traefik.io/traefik/v2.0/middlewares/basicauth/) with user:pass logic, although we could have used any external authentication services (AWS, etc.)

**Note** I had some trouble when generating them on my Centos8 with __htpasswd__ as they were not recognized in Traefik. I had to use an online generator.

You can use this command to generate your own [user/password](https://xkcd.com/936/)
```
$ echo $(htpasswd -nb xkcd <VERY SECURE PASSWORD>) | sed -e s/\\$/\\$\\$/g
xkcd:$$apr1$$<VERY SECURE HASH>
```

Now we can write our __dynamic_conf.yml__

```
$ cat dynamic_conf.yml 
http:
    routers:
        http_router:
            rule: "Host(`binsh.io`)"
            service: web
            middlewares:
                    - traefik-https-redirect
            tls:
                    certResolver: letsencrypt
        traefik_router:
            entrypoints: http
            rule: "Host(`traefik.binsh.io`)"
            service: api@internal
            middlewares: 
                - traefik-https-redirect
        traefik_secure_router:
            entrypoints: https
            rule: "Host(`traefik.binsh.io`)"
            middlewares: 
                - traefik-auth
            tls:
                    certResolver: letsencrypt
            service: api@internal
        
    services:
        web:
            loadBalancer:
                servers:
                    - url: "http://httpd/"


    middlewares:
            traefik-auth:
                    basicAuth:
                            users: 
                                - "<USER>:$apr1$<PASS HASH>"
            traefik-https-redirect:
                    redirectScheme:
                            scheme: https
                            permanent: true
```

We use a subdomain to redirect users going for web content (top domain binsh.io) and the ones going for Traefik dashboard (traefik.binsh.io)

All traffic is now forced into HTTPS with a valid certificate (which will be automatically renewed by Traefik), and we only force an authentication for users going onto Traefik dashboard

We can now start our docker-compose to finish adding HTTPS and auth to our infrastructure
```
$ docker-compose up -d --scale httpd=3
Starting httpd-service_traefik_1 ... 
Starting httpd-service_traefik_1 ... done
Starting httpd-service_httpd_1   ... done
Creating httpd-service_httpd_2   ... done
Creating httpd-service_httpd_3   ... done
```

HTTPS on binsh.io:
![image](https://user-images.githubusercontent.com/72258375/146785667-71cc256b-aa69-496c-b026-99b84485f3cd.png)

And on traefik.binsh.io (after basicAuth):
![image](https://user-images.githubusercontent.com/72258375/146786440-28a8859e-1460-4aa3-937a-c9f09eab7776.png)

Now that we added our proxy, we are able to have HTTPS content on our docker container, our infrastructure could be running live. But we need a way to monitor this host. Imagine we run into a disk failure, we need to have metrics on how It happened, and be alerted when It happens (or before even).

## Prometheus and Grafana

We want to install Prometheus and Grafana, they will be our monitoring stronghold to retrieve and analyze any collected metrics.

We will not bother with high-availability/fault-tolerant issues for now, this is a subject on which I'm not finding any design patterns. Only answer I got was "Use sharding and only one prometheus server per datacenter", but It doesn't cover any case on when the prometheus server has an issue (hardware failure or else).

### Prometheus installation

> Prometheus is an open-source systems monitoring and alerting toolkit originally built at SoundCloud in 2012. Prometheus collects and stores its metrics as time series data, i.e. metrics information is stored with the timestamp at which it was recorded, alongside optional key-value pairs called labels.

[Why use time series collection ?](https://sre.google/sre-book/production-environment/)

Typically, metrics are best used for monitoring, profiling, and alerting. The efficiency of summarizing data makes them great for monitoring and performance profiling because you can economically store long retention periods of data, giving you dashboards that look back over time. They are also great for alerting because they are fast and can trigger notifications almost instantaneously without the need for expensive queries. Metrics represent roughly 90% of the monitoring workload. [source](https://www.splunk.com/en_us/blog/devops/metric-log-monitoring-really-need.html)

Later on, we will think on adding a log-based monitoring (like Filebeat or else) and trace-based monitoring (like Jaeger).

Again, we have a provided prometheus docker that we can use out-of-the-box:
- https://docs.docker.com/config/daemon/prometheus/
- https://hub.docker.com/r/prom/prometheus

Our endgoal is to have a prometheus service available which we can access on __prometheus.binsh.io__

We create a **prometheus.yml** which will be the configuration, It should be static across all prometheus docker since It will define scrape_interval and targets

```
$ cat prometheus.yml 
# my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
      monitor: 'binsh-monitor'

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first.rules"
  # - "second.rules"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'docker'
         # metrics_path defaults to '/metrics'
         # scheme defaults to 'http'.

    static_configs:
      - targets: ['172.17.0.1:9323']
```

**Note** Experimental test: docker daemon can now export metrics onto Prometheus

The IP for the docker job is the docker0 interface

```
$ ip addr show docker0
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:2f:68:96:ac brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
```

Funny thing is : [the documentation recommends using localhost](https://docs.docker.com/config/daemon/prometheus/), but we can't access those metrics from the loopback device when running prometheus inside docker. Even if we try to expose the port on the host, It does not work.

You have to amend (or create if not existing) **/etc/docker/daemon.json** and add

```
$ cat /etc/docker/daemon.json
{
  "metrics-addr" : "0.0.0.0:9323",
  "experimental" : true
}
```

We have to bind it on 0.0.0.0 (any addr) because prometheus might need to access it from outside, but this could be a security issue and we will tackle it later.

Then we have to restart the docker service (be careful of shutting down any docker running)

```
$ sudo systemctl daemon-reload                         
$ sudo systemctl restart docker
 ```

We will later on check on the differences between cadvisor metrics and the one retrieved from the daemon itself.

For now, we only bother about monitoring our single host with a static configuration. Later on, when we scale to multiple hosts, we will have to dynamically update the host list to search for them. It can be done with DNS, AWS, IP, file based configuration.

### Grafana installation

> Grafana open source is open source visualization and analytics software. It allows you to query, visualize, alert on, and explore your metrics, logs, and traces no matter where they are stored. It provides you with tools to turn your time-series database (TSDB) data into insightful graphs and visualizations.

The project has since then branched into multiples components, with Grafana dashboard (the one we are using), Loki (Prometheus but for logs) and Tempo (for correlation)

Grafana docker:
- https://grafana.com/docs/grafana/latest/installation/docker/
- https://hub.docker.com/r/grafana/grafana

Our endgoal is to have a grafana service available at __grafana.binsh.io__ and able to reach prometheus service

Configuration-wise, we want to amend a few parameters, 

Normally, you could retrieve a base file with this type of command:
```
docker run --rm grafana/grafana-oss cat /etc/grafana/grafana.ini > base-custom.ini
```

But the way this image was made is .. with never-ending script waiting for logs, so the container can never stop itself with __--rm__ argument

So we have to improvize by creating the container, executing a command inside it, then shutting it down, use it at your own risk:
```
docker run -d grafana/grafana | xargs -I % sh -c 'docker exec % cat /etc/grafana/grafana.ini > base-grafana.ini; docker stop %'
```

It creates a new file __base-grafana.ini__ with the default grafana configuration.

The file is 1k lines long, but everything has defaults so we will just leave what's important to us in case we need to amend them.

Then we create our target __grafana.ini__ that will be used on the grafana container spawned by docker-compose

```
$ cat grafana.ini
################################### General ###################################
app_mode = production

instance_name = grafana.binsh.io

#################################### Paths ####################################
[paths]
# Directory where grafana can store logs
;logs = /var/log/grafana

# Directory where grafana will automatically scan and look for plugins
;plugins = /var/lib/grafana/plugins

# folder that contains provisioning config files that grafana will apply on startup and while running.
;provisioning = conf/provisioning

#################################### Server ####################################
[server]
# The http port  to use
;http_port = 3000

#################################### Analytics ####################################
[analytics]
reporting_enabled = false
check_for_updates = false

#################################### Security ####################################
[security]
disable_initial_admin_creation = true
admin_user = <VERY SECURE USER>
admin_password = <VERY SECURE PASSWORD>

#################################### Users ###############################
[users]
allow_sign_up = false

#################################### Basic Auth ##########################
[auth.basic]
;enabled = true

```

### Docker-compose file

Now that we have our grafana and prometheus configurations, we can create our docker-compose file

```
$ cat docker-compose.yml
version: "3.9"
services:
        prometheus:
                ports:
                        - "36200:9090"
                image: "prom/prometheus"
                volumes:
                        - prometheus-storage:/prometheus
                        - $PWD/prometheus.yml:/etc/prometheus/prometheus.yml
                networks:
                        - proxy
        grafana:
                ports:
                        - "36300:3000"
                image: "grafana/grafana-oss"
                volumes:
                        - grafana-storage:/var/lib/grafana
                        - $PWD/grafana.ini:/etc/grafana/grafana.ini
                depends_on:
                        - "prometheus"
                networks:
                        - proxy

networks:
        proxy:
                driver: bridge


volumes:
        grafana-storage:
        prometheus-storage:
```

For now we will let them on the host network, later on we will have them behind Traefik in their own secluded network.

One part stands out : We added two volumes so we do not lose any data in case any container crash
- On grafana It saves us any dashboard/user we created
- On prometheus It saves all metrics retrieved from the host, but I think prometheus keeps anything under 2 hours in memory and only writes it on disk If it is any older, so we would lose any recent data (We will need data replication to avoid this) 

Also we wait on prometheus to start for spinning up Grafana, as the dashboard would be useless without any data to pull from.

### Services configuration

Now all we need to do is check our service health, for now they are not behind any proxy, so we can access them on their port directly (ie. :36200/36300)

Let's check Prometheus, are our targets defined in our configuration able to spit up metrics?

![image](https://user-images.githubusercontent.com/72258375/146982871-2c00b65a-05e4-4888-b384-7b0f4398c41c.png)

Now can our Grafana retrieve those Prometheus metrics ?

We connect to grafana and add our datasource:

![image](https://user-images.githubusercontent.com/72258375/146982447-8b41f70b-e8e1-4bca-a659-724bfa8b8221.png)

And It works ! We have our (already provided) dashboard with metrics:

![image](https://user-images.githubusercontent.com/72258375/146982682-a0e36452-0084-4948-bd31-929080318930.png)

We could create our own dashboard and even our own metrics once we get up and running, but for now we will just use already-made dashboard.

### Networks and routing

Now that prometheus and grafana are running well in their own containers, we can move onto securing the stack

Let's start by questionning ourselves on what we want to expose.

We currently have this setup:

![image](https://user-images.githubusercontent.com/72258375/146987420-fa4c338b-6a11-498d-a784-5cfdfe2e0018.png)

Our end-goal is to have something cleaner like this:

![image](https://user-images.githubusercontent.com/72258375/146994602-7e22b07b-2537-4a4c-a3d1-3d6fa0127f4e.png)

So we will need to perform these two steps:

- Separate Traefik into its own docker-compose and add rules for docker/prometheus routing
- Put prometheus/Grafana in their own network space

#### Separate Traefik

First, let's split our current docker-compose for httpd-service.

Currently, we have:
```
cat docker-compose.yml
version: "3.9"
services:
        httpd:
		ports: 35000-35100:80
                image: "httpd:2.4"
                volumes:
                        - ./binsh/:/usr/local/apache2/htdocs/
                        - ./my-httpd.conf:/usr/local/apache2/conf/httpd.conf
                networks:
                        - webzone
        traefik:
                image: traefik:latest
                restart: unless-stopped
                command: --api --providers.docker
                ports:
                        # The HTTP port
                        - "80:80"
                        - "443:443"
                volumes:
                        # So that Traefik can listen to the Docker events
                        - /var/run/docker.sock:/var/run/docker.sock
                        - $PWD/traefik.yml:/etc/traefik/traefik.yml
                        - $PWD/dynamic_conf.yml:/dynamic_conf.yml
                        - $PWD/acme.json:/acme.json
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

First, we dont have to set ports nor networks on httpd container, It wasn't necessary as traefik and httpd are sharing the same network (http-service_default), we can remove it.

From docker-compose docs on networks:
> By default Compose sets up a single network for your app. Each container for a service joins the default network and is both reachable by other containers on that network, and discoverable by them at a hostname identical to the container name.

Then we can remove the entire traefik part, It will be moved to its own docker-compose file in another directory

Let's create this directory before we proceed any further

```
$ mkdir traefik-service
$ tree .
.
├── httpd-service
│   ├── acme.json
│   ├── binsh
│   │   ├── index.html
│   ├── docker-compose.yml
│   ├── dynamic_conf.yml
│   ├── my-httpd.conf
│   └── traefik.yml
├── monitoring-service
│   ├── base-grafana.ini
│   ├── docker-compose.yml
│   ├── grafana_data
│   ├── grafana.ini
│   ├── prometheus_data
│   └── prometheus.yml
└── traefik-service
```

We simply copy __docker-compose.yml__ and traefik related files located in httpd-service into traefik-service (so we will not have to retype everything once we get there)

```
$ cp httpd-service/docker-compose.yml traefik-service 
$ cp httpd-service/dynamic_conf.yml traefik-service  
$ cp httpd-service/traefik.yml traefik-service     
$ tree traefik-service 
traefik-service
├── docker-compose.yml
├── dynamic_conf.yml
└── traefik.yml
└── acme.json
```

Now we can modify our docker-compose in httpd-service directory

```
$ cat docker-compose.yml
version: "3.9"
services:
        httpd:
                image: "httpd:2.4"
                volumes:
                        - ./binsh/:/usr/local/apache2/htdocs/
                        - ./my-httpd.conf:/usr/local/apache2/conf/httpd.conf
                networks:
                        - traefik
                        - default
networks:
        traefik:
                external: true
                name: traefik-service_default
```

Here we only have our httpd server running. We could use a single command line instead of using docker-compose, but if we ever need to add a database or more, we can easily add it.

One inconvenience is we have to join Traefik network which will be started through another docker-compose, and we run into ["chicken or egg"](https://en.wikipedia.org/wiki/Chicken_or_the_egg) issue. We can't start our docker-compose unless traefik network is up, this is usually fine as we can't access the server anyway if our proxy is not up, but this is still a hard dependency which will require scheduling

We could have made Traefik join httpd network instead, but If we think about it, scaling-wise, this is a bad idea. We do not want to amend Traefik docker-compose file everytime we will add or remove a service like httpd (as It will have to update its network every time).

Now let's set up **traefik-service** (that we previously copied files onto)

We only have to amend our docker-compose file by removing the httpd:

```
$ cat docker-compose.yml 
version: "3.9"
services:
        traefik:
                image: traefik:latest
                restart: unless-stopped
                command: --api --providers.docker
                ports:
                        - "80:80"
                        - "443:443"
                volumes:
                        # So that Traefik can listen to the Docker events
                        - /var/run/docker.sock:/var/run/docker.sock
                        - $PWD/traefik.yml:/etc/traefik/traefik.yml
                        - $PWD/dynamic_conf.yml:/dynamic_conf.yml
                        - $PWD/acme.json:/acme.json
```

Let's clean-up any networks remnants and start traefik

```
$ docker network prune
$ docker-compose up -d                
Creating network "traefik-service_default" with the default driver
Creating traefik-service_traefik_1 ... done
```

Then we start our httpd containers

```
$ docker-compose up -d --scale httpd=3   
Creating network "httpd-service_default" with the default driver
Creating httpd-service_httpd_1 ... done
Creating httpd-service_httpd_2 ... done
Creating httpd-service_httpd_3 ... done
```

And we test web access (either by browser or command line):

```
$ curl -IL http://binsh.io
HTTP/1.1 308 Permanent Redirect
Location: https://binsh.io/

HTTP/2 200 

$ curl -IL http://traefik.binsh.io
HTTP/1.1 308 Permanent Redirect
Location: https://traefik.binsh.io/

HTTP/2 401 
www-authenticate: Basic realm="traefik"
```

Both routes are working as expected (redirection from http to https and basic-auth on Traefik dashboard), so we can move on the next part

#### Add prometheus and grafana logic for Traefik routing

Let's add prometheus and grafana routing on Traefik configuration now !

We don't have much to do as we already did it for binsh.io

First we create two DNS records, we could use A (IP <-> FQDN) or CNAME (FQDN <-> FQDN) types here, but I will prefer using CNAME for now as they are hosted on the same IP (saves cost and time for your computer, you are welcome)

Here we use __nslookup__ to check DNS records, It's packaged in bind-utils on Centos8 (not installed by default)

```
$ nslookup prometheus.binsh.io
Non-authoritative answer:
prometheus.binsh.io     canonical name = binsh.io.
Name:   binsh.io

$ nslookup grafana.binsh.io   
Non-authoritative answer:
grafana.binsh.io        canonical name = binsh.io.
Name:   binsh.io
```

And we get the resulting dynamic configuration for Traefik:

```
$ cat dynamic_conf.yml 
http:
        routers:
                http_router:
                        rule: "Host(`binsh.io`)"
                        service: web
                        middlewares:
                                - traefik-https-redirect
                        tls:
                                certResolver: letsencrypt
                grafana_router:
                        rule: "Host(`grafana.binsh.io`)"
                        service: grafana
                        middlewares:
                                - traefik-https-redirect
                                - traefik-auth
                        tls:
                                certResolver: letsencrypt
                prometheus_router:
                        rule: "Host(`prometheus.binsh.io`)"
                        service: prometheus
                        middlewares:
                                - traefik-https-redirect
                                - traefik-auth
                        tls:
                                certResolver: letsencrypt
                traefik_router:
                        entrypoints: http
                        rule: "Host(`traefik.binsh.io`)"
                        service: api@internal
                        middlewares: 
                                - traefik-https-redirect
                traefik_secure_router:
                        entrypoints: https
                        rule: "Host(`traefik.binsh.io`)"
                        middlewares: 
                                - traefik-auth
                        tls:
                                certResolver: letsencrypt
                        service: api@internal
        
        services:
                web:
                        loadBalancer:
                                servers:
                                        - url: "http://httpd/"
                grafana:
                        loadBalancer:
                                servers:
                                        - url: "http://grafana:3000/"
                prometheus:
                        loadBalancer:
                                servers:
                                        - url: "http://prometheus:9090/"

        middlewares:
                traefik-auth:
                        basicAuth:
                                users: 
                                        - "<USER>:$apr1$<PASSWORD VERY SECURE>"
                traefik-https-redirect:
                        redirectScheme:
                                scheme: https
                                permanent: true
```

We added two routers and services, one for Grafana on port 3000 and one for Prometheus on port 9090. Unfortunately Traefik is unable to find these port dynamically like he did for httpd. I guess we would have to change prom/grafana default port to 80 and It could work without indicating ports, but why bother.

We also added HTTPS redirection and basic-auth on both services, because why not.

Now we will be able to access prometheus and grafana through Traefik as long as they are on the same docker network.

#### Put prometheus and grafana behind Traefik

Now we can move Grafana and Prometheus into their own network space:

The resulting docker-compose file:

```
$ cat docker-compose.yml 
version: "3.9"
services:
        prometheus:
                image: "prom/prometheus"
                volumes:
                        - prometheus-storage:/prometheus
                        - $PWD/prometheus.yml:/etc/prometheus/prometheus.yml
                networks:
                        - traefik
        grafana:
                image: "grafana/grafana-oss"
                volumes:
                        - grafana-storage:/var/lib/grafana
                        - $PWD/grafana.ini:/etc/grafana/grafana.ini
                depends_on:
                        - "prometheus"
                networks:
                        - traefik

networks:
        traefik:
                external: true
                name: traefik-service_default

volumes:
        grafana-storage:
        prometheus-storage:
```

We can remove any port exposure/mapping, as they will connect to traefik network. We could have created an internal network for prometheus -> grafana traffic but It would not add much value.

Now let's try to start our prometheus/grafana services and test them through Traefik

Can we still access those services through our custom ports (36200/36300) ? No we can't since we removed the exposure from the docker-compose file

```
$ curl http://binsh.io:36200
curl: (7) Failed to connect to binsh.io port 36200: Connection refused
$ curl http://binsh.io:36300
curl: (7) Failed to connect to binsh.io port 36300: Connection refused
```

Can we access them through Traefik ? Yes, and It even redirects to https with a valid TLS certificate and basic authentication, nice !

![image](https://user-images.githubusercontent.com/72258375/147015794-67f4cc24-6e8a-4acb-a32e-176dc5c04e41.png)

![image](https://user-images.githubusercontent.com/72258375/147015819-680ad2f1-1020-4d26-9a13-b2e8713c36f8.png)


We reached our goal, and even removed any left-over ports that were not useful, so we can update our architecture as such:

![image](https://user-images.githubusercontent.com/72258375/147016044-b5fb7dcb-7bed-40ad-850b-871795c647ba.png)


## Node_exporter and Cadvisor

Now that we have somewhere to send our monitoring onto, we can start collecting informations across the board

We will node_exporter for collecting host metric (how is our hardware doing) and Cadvisor for docker metrics (are our containers running into any bottlenecks)

https://hub.docker.com/r/prom/node-exporter
https://hub.docker.com/r/google/cadvisor/

We create a new directory where we can begin our docker-compose file

```
$ cat agent-monitoring-service
$ touch docker-compose.yml
```

** UNDER CONSTRUCTION **