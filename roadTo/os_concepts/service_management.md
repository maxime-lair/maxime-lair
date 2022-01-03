# Service management

In this article, we will take a look at how service management is used in Linux, first by defining it, understanding its behavior and configuration, and some useful commands.

_Note: Im running a CentOS9 Stream in this article, It came out this very month, I will not be covering UNIX or Windows, only Linux_

We will be focusing on the newer system *systemd* - we will not talk about its ancestor (sysV) or competitors (upstart..)

## Definition

All processes running on the system are child processes of the *systemd* init process. It is an init system used to boostrap you from the kernel to user space.

![image](https://user-images.githubusercontent.com/72258375/147766518-0ad30710-0a49-4b6e-b35c-afc396c4f9a7.png)

![image](https://user-images.githubusercontent.com/72258375/147766425-2ccbf342-a66b-4cf5-980a-3b960e2715b2.png)

*systemd* is rather new, as It was developped in 2010 and stable as of 2015. It is rapidly becoming the most used init process, but has some concerns on its inner security.

It will be considered as a system and service manager. For those that haven't noticed, [It is a play on words](https://en.wikipedia.org/wiki/System_D) refering to its quick adapting ability, but for real, the **d** in _systemd_ refers to _daemon_, and If you need to refer to it, call it **System daemon**, not **System D**. 

It is hard to define as *systemd* as a good or bad news for Linux. While It is praised by developers and users alike for its reliable parallelism during boot and centralized management of processes, daemons, services and mount points, It strayed away from the UNIX philosophy by its design (e.g. mission creep/bloat feeling).

We will focus on the service management part on *systemd* and the init process will be covered in another article.

## What does systemd manage ?

First, It does *NOT* manage anything in _/etc/init.d/_. You should never add configuration there, as It will have no effect. There is backwards compatibility with SysV init scripts, but they will be not searched in this *deprecated* directory.

You can explore _/etc/systemd/_ instead, It gives an idea of the inner architecture

![image](https://user-images.githubusercontent.com/72258375/147768945-3c5fb5f9-af67-4c21-8ef6-9cd1f69a5c9b.png)

You can analyze each file full configuration with `systemd-analyze cat-config [PATH_TO_FILE]`

At its core, *systemd* manages units, and there is 11 available, highlighted in bold are the most important:
| Units | Description |
| --- | --- |
| Service | **Start and control daemons and processes they consit of, It is the most used** |
| Socket | **Encapsulate local IPC or network sockets in the system, useful for socket-based activation** |
| Target | **Useful to group other units through a chain of dependencies** |
| Device | **Expose kernel devices and may be used to implement device-based activation** |
| Mount | **Control mount points in the file system** |
| Automount | For on-demand mounting of file systems (hot-plug..) |
| Timer | **Useful for triggering activation of other units based on timers** |
| Swap | Similar to mount units, encapsulate memory swap components of the operating system |
| Path | Used to activate other services when file system objects change |
| Slice | **Group and manage processes and resources (cgroups)** |
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
| _/run/systemd/system_ | Systemd unit files created at run time. This directory takes precedence over the default |
| _/etc/systemd/system_ | Systemd unit files created by systemctl enable as well as unit files added for extending a service. This directory takes precedence over the run-time one  |

An example of _crond.service_ unit configuration, part of the default configuration:

![image](https://user-images.githubusercontent.com/72258375/147774495-cb3060bf-e1b1-4dba-aab2-90fe13012765.png)

You can notice its scheduling dependencies on _After=_ and _WantedBy_ ; It is also able to restart itself on a specific timer.

*Note:* It's common case to have those service units configuration created in the three locations, and there is a link on higher priority paths towards the default one.
Be careful when you change it, as anything written in the default unit path (in _/usr/lib/_) will be overwritten at each OS update.

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

Let's preface it by saying _systemd_ does not communicate with services that have not been started by it. All is managed through a process PID, and used to query and manage the service. If you did not start your daemon through _systemd_, It will be impossible to query its state through _systemd_ commands.

There is two different types of state available on an unit:
- Loaded : If the unit file has been found, and It is enabled
- Active : If the unit is running or stopped

Since It is required to load an unit before running it, you need to consider both types to get a unit's status.

### Unit loading

A unit has to be loaded if you need to run it. This state depends entirely on the unit configuration, and It can be one of the following:
- _loaded_
- _not-found_ (e.g. not found in the three possibles paths)
- _bad-setting_
- _error_ (e.g. set a masked service as enabled for example)
- _masked_

_An example of bad-setting, where we missed the initial / in the path_

![image](https://user-images.githubusercontent.com/72258375/147968650-9bd9cd7b-0b94-49fb-8e50-ad503c5e111b.png)

After correcting the issue:

![image](https://user-images.githubusercontent.com/72258375/147968759-47a31a53-faa4-4a4e-b573-4ee189ea155b.png)


A note on *mask* : It is a stronger version of __disable__ ; It links the unit file to _/dev/null_, making it impossible to start them. It prohibits all kinds of activation, including enablement or manual activation. It can be used to prevent accidentally using a service that conflicts with a running one.

Once It is loaded, It will look in its configuration for its enablement state ([Install] section of the unit file). It hooks the unit into its various suggested places (e.g. the unit is automatically started on boot or when a particular kind of hardware is plugged in).

### Unit activation

Your unit can be either **started** or **stopped**, but It can actually be more refined than that. A unit possesses two levels of activation state: 
- High-level (often called **active**), and can take the following state:
  - active
  - inactive
  - failed
  - reloading
  - activating
  - deactivating
- Low-level called **sub**, whose values depend on unit-type specific detailed state of the unit
You can check what substates is available per unit type with `systemctl --state=help`

![image](https://user-images.githubusercontent.com/72258375/147956854-86cfa91d-400d-4fcc-a0b2-cbb4d027aa14.png)


## Create our own service unit

Let's create our own service unit, which will simply repeat a ping/pong in a file. It will help us understand its state, and how to use a custom file as a service. We could imagine implementing a socket, device, or any other types of units.

Two things to note before we start:
- System services are **unable** to read from the standard input stream, and when started, It connects its standard input to _/dev/null_ to prevent any interaction.
- System services do not inherit any context (e.g. environment variables like _HOME_ or _PATH_)  from the invoking user and their session. It runs in a clean execution context. You can check out your environment variables by typing `env` or `systemctl show-environment` in your shell.

![image](https://user-images.githubusercontent.com/72258375/147947040-10831d0b-76dd-4de5-b026-211c02a3fd85.png)

![image](https://user-images.githubusercontent.com/72258375/147975659-7c05a685-07f7-4d8f-874c-64f85ad9b106.png)


Now, let's create our service unit, in _/etc/systemd/system_

We will call it pingpong.service:

![image](https://user-images.githubusercontent.com/72258375/147974302-153c544d-31de-4c15-acca-2fbc9d1364d4.png)

We write a simple script, which repeatedly write ping/pong into a named pipe

![image](https://user-images.githubusercontent.com/72258375/147973142-27ffeb3f-dd68-40d8-b472-2bea5b0b77ef.png)

Let's start it ! We check its status beforehand

![image](https://user-images.githubusercontent.com/72258375/147974352-e4c4a47e-4aba-4b02-a87a-d261ef747851.png)

![image](https://user-images.githubusercontent.com/72258375/147974388-671a39d6-d935-464c-88c0-6fa376874925.png)

We can see It created a pipe successfully

![image](https://user-images.githubusercontent.com/72258375/147974408-42dafe1f-baa8-4646-9d41-44d15d196365.png)

The script is not perfect, as It will be blocked if someone else access this pipe, as `read` is blocking. The script location is also not perfect, as It depends on a non-sudo user, and represents a security risk, It would be better to review its permission and put it in _/usr/local/bin_

Let's stop it, and check It deleted our named pipe

![image](https://user-images.githubusercontent.com/72258375/147974591-a4978d79-47de-4e23-9a41-aa39a6d420a3.png)

![image](https://user-images.githubusercontent.com/72258375/147974601-1833498b-dc0f-4ef3-8291-ff406201d7eb.png)

All good ! It's also possible to create a unit template, if you want to create a skeleton of your units.

## Useful commands

To reload and apply unit changes:
```
systemctl daemon-reload
systemctl restart [UNIT_NAME]
```

To have an overview of overridden/modified unit files, use `systemd-delta`

![image](https://user-images.githubusercontent.com/72258375/147975270-8f0450b8-b33b-440d-a13a-f129238f199f.png)

To view groupings of processes system-wise, use `systemd-cgls`

![image](https://user-images.githubusercontent.com/72258375/147975420-e30702fc-be4f-4ad4-b830-ac362969dbeb.png)


> Credits
> 
> https://en.wikipedia.org/wiki/Systemd
>
> https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/chap-managing_services_with_systemd
>
> https://www.computernetworkingnotes.com/linux-tutorials/
>
> https://www.freedesktop.org/software/systemd/man/systemctl.html
>
