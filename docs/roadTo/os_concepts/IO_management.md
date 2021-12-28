# I/O management

In/Out management on Linux allows us to understand how data flows in Linux, from information coming from the network card, to the hard-drive, passing by CPU, RAM or others devices.

All systems will always be limited by their weakest link, or [low-hanging fruit](https://dictionary.cambridge.org/dictionary/english/low-hanging-fruit)

We will try to understand how to exploit this architecture to manage bottlenecks. 

_Note:_ I'm using a Centos 9 stream which came out this month, only Linux will be covered here.

## Definition

To make a computer work properly, *buses* must be provided that let information flow between CPU(s), RAM and others devices that are connected to the system.

*Devices* can be purely an *input* type (e.g. keyboard or mouse), an *output* type (e.g. printer, display screen) or both an input and output device (e.g. disk)

Regardless of their purpose, they must communicate through the *system bus* (e.g. typically the PCI), but they are not always directly connected to it. They can flow through *interfaces* first.

Interfaces were created to easen the CPU's load to avoid having to understand and respond to each and every device. Also, sending signals on this system bus requires a very low electrical power, which makes the connecting cable very short (a few centimeters).

Interfaces are also called *I/O controllers*, and they typically holds three types of internal registers: data, command and status.

Besides the system bus, several other types exists, like ISA or USB, that communicate through bridges. 

An image speak louder than words:

![image](https://user-images.githubusercontent.com/72258375/147587672-f4b525a4-9849-4581-b22e-af9fdc50c6ba.png)



## Concepts

### Accessing I/O devices

It is possible to have direct control of any I/O devices through their controllers, but this would lead to a multitude of problems (unintentionnal or malicious).
To avoid these problems, Linux provide routines to conveniently access those devices, made of system calls.


## Network I/O

## Disk I/O



## To go further



> Credits
>
> https://doc.lagout.org/operating%20system%20/linux/Understanding%20Linux%20Kernel.pdf
>
> https://applied-programming.github.io/Operating-Systems-Notes/8-IO-Management/#io-management
>
> https://www.oreilly.com/library/view/understanding-the-linux/0596002130/ch13.html
>
> https://www.kernel.org/doc/html/latest/driver-api/device-io.html
>
> https://www.redhat.com/sysadmin/io-reporting-linux
> 
> https://unix.stackexchange.com/questions/55212/how-can-i-monitor-disk-io
>
> https://haydenjames.io/linux-server-performance-disk-io-slowing-application/
>
> https://www.linuxtopia.org/online_books/introduction_to_linux/linux_I_O_resources.html
