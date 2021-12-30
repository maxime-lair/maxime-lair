# Service management

In this article, we will take a look at how service management is used in Linux, first by defining it, understanding its behavior and configuration, and some useful commands.

_Note: Im running a CentOS9 Stream in this article, It came out this very month, I will not be covering UNIX or Windows, only Linux_

We will be focusing on the newer system *systemd* - we will not talk about its ancestor (sysV) or competitors (upstart..)

## Definition

All processes running on the system are child processes of the *systemd* init process. It is an init system used to boostrap you from the kernel to user space.

![image](https://user-images.githubusercontent.com/72258375/147766518-0ad30710-0a49-4b6e-b35c-afc396c4f9a7.png)

![image](https://user-images.githubusercontent.com/72258375/147766425-2ccbf342-a66b-4cf5-980a-3b960e2715b2.png)

*systemd* is rather new, as It was developped in 2010 and stable as of 2015. It is rapidly becoming the most used init process, but has some concerns on its inner security.

It will be considered as a system and service manager. For those that haven't noticed, [It is a play on words](https://en.wikipedia.org/wiki/System_D) refering to its quick adapting ability.

It is hard to define as *systemd* as a good or bad news for Linux. While It is praised by developers and users alike for its reliable parallelism during boot and centralized management of processes, daemons, services and mount points, It strayed away from the UNIX philosophy by its design (e.g. mission creep/bloat feeling).

We will focus on the service management part on *systemd* and the init process will be covered in another article.

## What does systemd manage ?

First, It does *NOT* manage anything in _/etc/init.d/_ ; this thing is GONE. You should never add configuration there, as It will have no effect.

You can explore _/etc/systemd/_ instead, It gives an idea of the inner architecture

![image](https://user-images.githubusercontent.com/72258375/147768945-3c5fb5f9-af67-4c21-8ef6-9cd1f69a5c9b.png)

You can analyze each file full configuration with `systemd-analyze cat-config [PATH_TO_FILE]`

At its core, *systemd* manages units, and there is 11 available, highlighted in bold are the most important:
| Units | Description |
| --- | --- |
| Service | *Start and control daemons and processes they consit of, It is the most used* |
| Socket | *Encapsulate local IPC or network sockets in the system, useful for socket-based activation* |
| Target | *Useful to group other units through a chain of dependencies* |
| Device | *Expose kernel devices and may be used to implement device-based activation* |
| Mount | *Control mount points in the file system* |
| Automount | For on-demand mounting of file systems (hot-plug..) |
| Timer | *Useful for triggering activation of other units based on timers* |
| Swap | Similar to mount units, encapsulate memory swap components of the operating system |
| Path | Used to activate other services when file system objects change |
| Slice | *Group and manage processes and resources (cgroups)* |
| Scope | Similar to service units, but for foreign processes management (e.g. init) |

Units are named after their configuration files, which can include positive or negative requirement dependencies as well as ordering.

One example of such unit is the cron daemon, used for scheduling your batch.

![image](https://user-images.githubusercontent.com/72258375/147771567-f18ae4b9-06fb-4a9c-9dd4-8403c27503ed.png)

To put it into perspective, my CentOS uses 370 unit files, with 141 loaded units

![image](https://user-images.githubusercontent.com/72258375/147773333-71a31b47-d4c2-4b57-9f3c-430ce901fcde.png)

![image](https://user-images.githubusercontent.com/72258375/147773306-5ae3ddd5-086f-420f-9be1-f35df4fa0216.png)

## How are units made ?

Each units is configured through a plain-text files, with a _.ini_ type syntax.

*systemd* stores them in three location, depending on their usage

| Path | Type of unit |
| --- | --- |
| _/usr/lib/systemd/system_ | systemd default unit distributed by RPM packages |
| _/run/systemd/system_ | Systemd unit files created at run time. This directory takes precedence over the directory with installed service unit files |
| _/etc/systemd/system_ | Systemd unit files created by systemctl enable as well as unit files added for extending a service. This directory takes precedence over the directory with runtime unit files.  |

An example of _crond.service_ unit configuration, part of the default configuration:

![image](https://user-images.githubusercontent.com/72258375/147774495-cb3060bf-e1b1-4dba-aab2-90fe13012765.png)

You can notice its scheduling dependencies on _After=_ and _WantedBy_ ; It is also able to restart itself on a specific timer.

*Note:* It's common case to have those service units configuration created in the three locations, and there is a link on higher priority paths towards the default one.
Be careful when If you try to change it, as anything written in the default unit path will be overwritten at each OS update.

![image](https://user-images.githubusercontent.com/72258375/147775146-a4a428fc-b659-429c-9790-fb865d88f6f2.png)

## Well known units

If you are interested in *systemd* service architecture, try out `systemctl list-dependencies`

![image](https://user-images.githubusercontent.com/72258375/147775707-5ede546d-296a-4fe0-b81a-42b9a6c93d92.png)

Among all the running units (and not only services), there is a few interesting ones that you might already know:
| Unit | Type | Used for |
| --- | --- | --- |
| proc-sys-fs-binfmt_misc | automount | all block/character devices |
| run-user-xxxx | mount | storing files used by running processes for that user |
| sys-kernel-debug | mount | Kernel debug file system |
| sys-kernel-tracing | mount | Kernel Trace file system |
| init | scope | System and service manager |
| auditd | service | Security auditing service |
| crond | service | Command scheduler |
| firewalld | service | Dynamic firewall daemon |
| NetworkManager | service | Handles network configuration |
| sshd | service | OpenSSH server daemon |
| systemd-journald | service | Journal service |
| systemd-logind | service | user login management |
| user@xxxx | service | User manager for UID xxxx |
| user | slice | User and session slice |
| dbus | socket | D-Bus System Message Bus Socket |
| network | target | Network component |

There is many more, and you can check a unit's critical chain with `systemd-analyze critical-chain [unit]`

![image](https://user-images.githubusercontent.com/72258375/147778492-b6201399-d94c-4e26-8b7b-8b54893e68b2.png)

If you need to have better boot time, you can check what take the longest.

## Possible state of units




## Create our own service unit

Ping / Pong

## Useful commands


> Credits
> 
> https://en.wikipedia.org/wiki/Systemd
>
> 
>
> 
>
> 
>
> 
> 
> 
