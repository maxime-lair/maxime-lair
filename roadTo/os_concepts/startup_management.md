# Service management

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
