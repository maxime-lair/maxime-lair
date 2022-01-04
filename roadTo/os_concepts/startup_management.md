# Start-up management

In this article, we will take a look at how init management is used in Linux, first by defining it, understanding its behavior and configuration, and some useful commands.

_Note: Im running a CentOS9 Stream in this article, It came out in December 2021, I will not be covering UNIX or Windows, only Linux_

We will be focusing on the newer system *systemd* - we will not talk about its ancestor (sysV) or competitors (upstart..)

## Definition

All processes running on the system are child processes of the *systemd* init process. It is an init system used to boostrap you from the kernel to user space.

![image](https://user-images.githubusercontent.com/72258375/147766518-0ad30710-0a49-4b6e-b35c-afc396c4f9a7.png)

![image](https://user-images.githubusercontent.com/72258375/147766425-2ccbf342-a66b-4cf5-980a-3b960e2715b2.png)

*systemd* is rather new, as It was developped in 2010 and stable as of 2015. It is rapidly becoming the most used init process, but has some concerns on its inner security.

It will be considered as a system and service manager. For those that haven't noticed, [It is a play on words](https://en.wikipedia.org/wiki/System_D) refering to its quick adapting ability, but for real, the **d** in _systemd_ refers to _daemon_, and If you need to refer to it, call it **System daemon**, not **System D**. 

It is hard to define *systemd* as a good or bad news for Linux. While It is praised by developers and users alike for its reliable parallelism during boot and centralized management of processes, daemons, services and mount points, It strayed away from the UNIX philosophy by its design (e.g. mission creep/bloat feeling).

We will focus on the startup management part on *systemd* and the service process will be covered in another article.

## How does systemd starts ?

Since RHEL 7 (Fedora 19+, Linux kernel 3.10.0-123), init scripts have been replaced with _service_ units.

While its predecessor *sysV* was using runlevels to define its startup process, **systemd** uses target units to start itself. Retro-compatibility wise, the system daemon has only limited support for runlevels, It has a number of target units that can be directly mapped to these runlevels, but not all can be directly mapped to runlevels. This is why It is recommended to avoid using the `runlevel` command, and also the reason we will not cover the different runlevels.

Let's focus on understanding how these **units** takes you from the boot phase to a useable system.

_Target units_ only purpose is to group together other systemd units through a chain of dependencies. 

To determine which target unit is used by default, we will use `systemctl get-default`

![image](https://user-images.githubusercontent.com/72258375/147990539-ff9c1a45-4a5b-4e74-872e-63969f285145.png)

This represents the system end-goal to ensure our system is fully loaded, let's check what It needs to be completed:

![image](https://user-images.githubusercontent.com/72258375/147990740-be09ae78-fd90-4270-89a5-255aa9681c6a.png)

_Note:_ Unlike `Requires`, `After` does not explicitly activate the specified units. This means that to load the _default.target_, the system will only care about _basic.target_, and If we analyze it:

![image](https://user-images.githubusercontent.com/72258375/147990694-4d08299e-55fc-4974-bc56-1cbba775fd68.png)

Let's check what _system.slice_ has in store. A slice unit is a concept for hierarchically managing resources of a group of processes. It is performed by creating a node in the _cgroup_ tree to limit resource applied to a specific slice.

First, let's understand what are _cgroups_, as they are an essential feature of the linux kernel (specially for containers).

### cgroups

**cgroup** is the Linux Control Group that limits, accounts for, and isolates the resource usage (CPU, memory, disk, I/O, network, etc..) of a collection of processes. The first version was developped at Google in 2006 and released in the linux kernel mainline in 2008. The version 2 was merged in linux kernel 4.5 (Fedora uses it since ~ 2019), no RHEL released with it yet at this time, my Centos 9 is on linux kernel 5.14, so this is still very new.

Main version difference is: unlike v1, _cgroup v2_ has only a single process hierarchy and discriminates between processes, not threads.

One of the design goals of _cgroups_ is to provide a unified interface, from controlling single processes (e.g. by using `nice`) to full operating system-level virtualization (e.g. LXC or docker).

_cgroups_ provides:
- Resource limiting
- Prioritization
- Accounting
- Control

A control group (_cgroup_) is a collection of processes that are bound by the same criteria and associated with a set of parameters or limits. The kernel provides access to multiple controllers through the _cgroup_ interface, like RAM or CPU usage.

You can check these collections through **systemd** with two commands: 

`systemd-cgls`

![image](https://user-images.githubusercontent.com/72258375/147994561-b7e7ab41-3fa2-4da0-a697-904f55eb04cb.png)

![image](https://user-images.githubusercontent.com/72258375/147994639-af9a6056-adb7-43ff-8958-f0c167fd6ad3.png)

`systemd-cgtop`

![image](https://user-images.githubusercontent.com/72258375/147994725-c144d867-e284-4c6f-9b54-d228f5a9863c.png)

![image](https://user-images.githubusercontent.com/72258375/147994712-eaf8ac79-c623-4fbc-8061-48d0d76c1f24.png)

There is also the `tc` command, a user-space utility program used to configure linux kernel packet scheduler.

Various projects use _cgroups_ as their basis, including **Docker**, **Hadoop**, **Kubernetes**, **systemd**

WIP


### System.slice

WIP
  
  
  
## Change target

**systemd** gives you the ability to change to a different target unit in the current session (requires `root`).

Just use `systemctl isolate [target-name]` to switch into the target unit, which will immediately stops all others non-required units (use at your own risk).

This is useful in case we want to repair our system, in case It is unable to complete a regular booting process.

For example, `systemctl rescue` allows you to switch to _rescue.target_, which provides a convenient single-user environment and mount all local file systems. It does not activate network interfaces or multiple user sessions. It ressembles `systemctl isolate rescue.target` but sends an informative message to all currently logged users in the system (wall).

![image](https://user-images.githubusercontent.com/72258375/147991663-3d4b7db0-d5f3-4d3b-891c-43d99a0f9c4c.png)

If you need to go further, you can use `systemctl emergency`, which provides the most minimal environment possible. It mounts the root file system only for reading, and does not attempt to mount any other local file systems.

![image](https://user-images.githubusercontent.com/72258375/147991899-a3a622e0-a035-4f46-9be3-96357a797d32.png)

## System power management

**systemd**, as a system manager, will also handle the power management command whenever you want to stop, reboot, suspend it. Any commands you use is a symlink to `systemctl` utility.

![image](https://user-images.githubusercontent.com/72258375/147992138-7199c6f2-2981-460d-bf9d-bacc1a7e51f8.png)

Each of these commands is a link to a target unit, which will try to stop the system as cleanly as possible.

A few differences to note:
- **halt** terminates all processes and shuts down the cpu
- **poweroff** is similar to _halt_ but also turns off the motherboard (lights, led, etc.)
- **shutdown** is similar to _poweroff_ but runs shutdown scripts beforehand to stop things gracefully
- **reboot** is a _shutdown_ and apply a hardware reset procedure so that the boot process takes over
- **suspend** saves the system state in RAM, and powers off most the device in the machine until It is turned back again
- **hibernate** saves the system state on the hard disk drive and powers off the machine until It is turned back again

![image](https://user-images.githubusercontent.com/72258375/147993247-392abb0c-0e6f-4e5a-8cab-e9301bae7fe5.png)

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
> https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v1/cgroups.html
