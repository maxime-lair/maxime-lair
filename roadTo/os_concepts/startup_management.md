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

One of the design goals of _cgroups_ is to provide a unified interface, from controlling single processes (e.g. by using `nice`) to full operating system-level virtualization (e.g. LXC or docker), in order to provide:
- Resource limiting
- Prioritization
- Accounting
- Control

A control group (_cgroup_) is a collection of processes that are bound by the same criteria and associated with a set of parameters or limits. The kernel provides access to multiple controllers through the _cgroup_ interface, these controllers can be Block IO, CPUSETS, HugeTLB, Memory, Network, Process number or RDMA.

You can check these collections through **systemd** with two commands: 

`systemd-cgls`

![image](https://user-images.githubusercontent.com/72258375/147994561-b7e7ab41-3fa2-4da0-a697-904f55eb04cb.png)

![image](https://user-images.githubusercontent.com/72258375/147994639-af9a6056-adb7-43ff-8958-f0c167fd6ad3.png)

`systemd-cgtop`

![image](https://user-images.githubusercontent.com/72258375/147994725-c144d867-e284-4c6f-9b54-d228f5a9863c.png)

![image](https://user-images.githubusercontent.com/72258375/147994712-eaf8ac79-c623-4fbc-8061-48d0d76c1f24.png)

There is also the `tc` command, a user-space utility program used to configure linux kernel packet scheduler.

Various projects use _cgroups_ as their basis, including **Docker**, **Hadoop**, **Kubernetes** and **systemd**.

You can find your currently defined cgroups in _/sys/fs/cgroup_ directory

![image](https://user-images.githubusercontent.com/72258375/148071480-c004e04d-5c9b-4490-bd6d-38254596eae2.png)

Notice how we find back our cgroup defined by _system.slice_ ; It itself will contain more cgroups defined in its hierarchy

![image](https://user-images.githubusercontent.com/72258375/148071867-57f9a276-b95f-4354-bdda-072114f1a9e5.png)

And its controllers (or subystem):

![image](https://user-images.githubusercontent.com/72258375/148072072-cd7c2160-6c08-45f3-869a-4d6e173503b1.png)


### System.slice

Now that we understand how cgroups is used to limit ressources usage per task groups, we can check how It works when our system starts up.

We can check which units our _system.slice_ is directly responsible for:

![image](https://user-images.githubusercontent.com/72258375/148075444-69ae40e9-e0d6-47f8-8baa-7d0c8990478f.png)

_system.slice_ is part of the four ".slice" units which form the basis of the hierarchy for assignment of resources for services, users and virtual machines/containers.

| Slice unit | Description |
| --- | --- |
| -.slice | Root of the slice hierarchy, does not usually contain units directly but may be used to set defaults for the whole tree |
| system.slice | By default, all system services started by **systemd** are found in this slice |
| user.slice | By default, all user processes and services started on behalf of the user |
| machine.slice | By default, all virtual machines/containers registered with *systemd-machined* are found in this slice |

## Bootup process

Now that we understand how _.slice_ units are used to control process resources through cgroups hierarchy tree, we go back to our _default.target_ critical-chain

![image](https://user-images.githubusercontent.com/72258375/148084906-a272df62-d4d9-4932-9717-caece6135914.png)

As a reminder, a usual bootup process goes as follow: 
- Power-up
- System firmware (BIOS/UEFI/EFI, etc.) will do minimal hardware initialization
- Boot loader stored on a persistent storage device (**systemd-boot** for UEFI, GRUB2, etc.) to invoke OS kernel from disk (or network)
- The kernel will then mounts an in-memory file system, generated by `dracut`, usually an _initramfs_, and interprets it as a file system
- initrd hands over control to the host's system manager (e.g. **systemd**) stored in the root file system
- **systemd** will probe all remaining hardware, mount all necessary file systems and spawn all configured services

The shutdown process does exactly the same as the bootup process, but in exact reverse.

You can check your bootloader configuration in _/boot/loader/entries/*-[kernel-version].conf_

![image](https://user-images.githubusercontent.com/72258375/148090884-87fea3a3-205f-45e8-ab91-1be7e1e93516.png)

Let's analyze each step to understand our bootup process. While this process is split up in various discrete steps, the boot-up process is highly parallelized so the order in which specific target units are reached is not deterministic, but still adheres to a limited amount of ordering structure.

In order to reach _multi-user.target_, we go through a few different targets (and their dependencies), namely:
- local-fs-pre.target
- local-fs.target
- sysinit.target
- basic.target
- network-pre.target
- network-online.target

If you wonder why this list is not the same as the one found in _default.target_ configuration:

![image](https://user-images.githubusercontent.com/72258375/148094531-ea0dcb0c-b8a8-484c-80fe-3442ed3191bc.png)

This is because the critical-chain is a tree of **required** units, _Wants_ is a weak dependency, if any of the wanted units does not start successfully, It has no impact on the _default.target_ activation.

Here is an incomplete view of some dependency for targets chain:

![image](https://user-images.githubusercontent.com/72258375/148115181-00fbd595-23d5-4a03-ad2c-b73c0aae9a70.png)


Of course we are missing lots of service and others units, but If It helps to see how It enables parallelism.

## Change target

Now that we understand how our bootup process works in order to reach our _default.target_ , how do we reverse that to make the system stop ?

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


## Conclusion

We discovered how **systemd** takes you from the system bootup process to his _default.target_ and how we can change this target to shutdown our system. There is much more to fully uncover this startup process, for example by applying cgroups to limit resources usage on a specific target.

Feel free to check out the credits below, as there were helpful in uncovering the surrounding shroud around **systemd startup process**.

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
>
> https://systemd.io
