# Project start

This page will be used to record the installation of a self-hosted devops environment.

The end-goal is to have an infrastructure running several services:
- Prometheus & Grafana for monitoring purpose
- Node_exporter (for host metrics) and Cadvisor (for docker metrics) on each host
- Traefik to handle routing and load-balancing
- Web application powered by httpd

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

We will a user named **produser** for running docker, I simply created it with useradd and added a password to it.

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

To spice it up, we will have 2 docker container, each running the same image, they will deliver the web server on the host on two differents ports : 8081 and 8082.
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
478222b0c467   httpd:2.4   "httpd-foreground"   About a minute ago   Up About a minute   0.0.0.0:8080->80/tcp, :::8080->80/tcp   my-apache-app
$ curl http://localhost:8080 
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
        web_1:
                ports:
                        - "8081:80"
                image: "httpd:2.4"
                volumes:
                        - ./binsh/:/usr/local/apache2/htdocs/
        web_2:
                ports:
                        - "8082:80"
                image: "httpd:2.4"
                volumes:
                        - ./binsh/:/usr/local/apache2/htdocs/
 ```
 
We indicate two services: web server 1 and 2 and we map the ports from (host) 808x to port 80 (httpd port in the container)

We use the provided httpd image, imagine we want to upgrade from version 2.4 to 2.5, we could just change one and check for any differences.

Then we indicate the HTML files we want to use, and where to place them on the container

We could do it through a Dockerfile, but the advantage of using **volumes** is the live update, if we modify any files on /binsh/ on the host, we do not need to restart any docker container, as the changes will be effective immediately. If we did a COPY through a dockerfile, this would not be the case.

Now we retrieve the web files we want to host:
```
$ git clone git@github.com:maxime-lair/binsh.git
```

Advantage is : If I want to update my webfiles, I can leave the container running, and just re-do a git clone to have it available live.

Now we can start the docker-compose:

```
$ docker-compose up 
Creating network "httpd-service_default" with the default driver
Creating httpd-service_web_1_1 ... done
Creating httpd-service_web_2_1 ... done
Attaching to httpd-service_web_2_1, httpd-service_web_1_1
web_1_1  | AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.18.0.2. Set the 'ServerName' directive globally to suppress this message
web_1_1  | AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.18.0.2. Set the 'ServerName' directive globally to suppress this message
web_1_1  | [Sun Dec 19 16:05:07.947010 2021] [mpm_event:notice] [pid 1:tid 140146190855488] AH00489: Apache/2.4.51 (Unix) configured -- resuming normal operations
web_1_1  | [Sun Dec 19 16:05:07.947197 2021] [core:notice] [pid 1:tid 140146190855488] AH00094: Command line: 'httpd -D FOREGROUND'
web_2_1  | AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.18.0.3. Set the 'ServerName' directive globally to suppress this message
web_2_1  | AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.18.0.3. Set the 'ServerName' directive globally to suppress this message
web_2_1  | [Sun Dec 19 16:05:07.909152 2021] [mpm_event:notice] [pid 1:tid 139777255918912] AH00489: Apache/2.4.51 (Unix) configured -- resuming normal operations
web_2_1  | [Sun Dec 19 16:05:07.909357 2021] [core:notice] [pid 1:tid 139777255918912] AH00094: Command line: 'httpd -D FOREGROUND'

web_1_1  | 92.88.11.91 - - [19/Dec/2021:16:05:41 +0000] "\x16\x03\x01\x02" 400 226
web_1_1  | 92.88.11.91 - - [19/Dec/2021:16:07:54 +0000] "\x16\x03\x01\x02" 400 226
web_1_1  | 92.88.11.91 - - [19/Dec/2021:16:09:00 +0000] "GET / HTTP/1.1" 200 3636
web_2_1  | 92.88.11.91 - - [19/Dec/2021:16:09:06 +0000] "GET / HTTP/1.1" 200 3636
```

We check on the host if we see our ports opened:
```
$ netstat -tlpn                                         
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:8081            0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:8082            0.0.0.0:*               LISTEN      -    
```

Sure enough, our web servers are up and running, able to deliver the web pages on port 8081 and 8082

We have some warnings at the web server start-up because we did not change the ServerName in the httpd configuration, as the process is unsure of the correct IP It is being hosted on. When we get our proxy running, we will be able to update this to our FQDN binsh.io

If you want to start your container in the background, you can add **-d** argument on the start

```
$ docker-compose up -d  
Starting httpd-service_web_1_1 ... done
Starting httpd-service_web_2_1 ... done
```

We will leave them started for the time being, but we will need to find a way to schedule maintenance at one point with kubernetes, crontab or else.

Let's now move on to setting up a proxy solution: traeffik

## Traeffik









