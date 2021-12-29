# Memory and storage

In this article, we will take a look at how memory and storage interact in Linux, the different technology available, and their perks and defaults

_Note: Im running a CentOS9 Stream in this article, It came out this very month, I will not be covering UNIX or Windows, only Linux_

## Physical memory

### Definition

We will try to focus on the different type of memory in Linux.
While there is the physical hardware that makes up RAM, and the virtual memory you see on Linux.

RAM was made to be performant, quick access on read and write, while disk can focus on long-term memory.

### Types of RAM

Most RAM today are of DDR-RAM type, which stands for *D*ouble *D*ata *R*ate and exist since 2002. Compared to a single data rate, Its performance is doubled (up to 3 GB/s) as It was able to read data on both the rising and falling edges of the clock signal.

DDR2 was then invented in 2004, delivering up to 6.5 GB/s bandwidth. 
It introduced the _dual-channel memory_ concept, where CPUs could communicate using a bus with the memory module through independent channels, essentially amping up the bandwidth as data could be sent on more than one channel.
Today, servers are usually designed with six to eight channels.

The most important part is : you can not use more than one type of memory per motherboard, they can only handle on type of memory (DDR2 or DDR3 or else..).
In reality, It goes even further than that as you only use memories of the same type, manufacturer and frequency.

Each DDR iteration made memory faster and more energy efficient. DDR3, which came out in 2007, made bandwidth go up to 15 GB/s.

Today, most servers are using DDR4, pushing up to 25GB/s, and we are slowly shifting towards DDR5, released in 2020, with 50 GB/s bandwidth.

If you try to get DDR5 memory now, It will probably cost you a lot of more than for DDR4, as It is still difficult to ramp up into mass-production.

_Note_: There is also _VRAM_ but It is only used in graphic cards, and It is a lot more expensive.

You might also notice some memory marked as *ECC* which stands for *E*rror *c*orrection *c*ode. ECC memory maintains a memory system immune to single-bit errors.
It decreases your memory overall performance by 2-3% and cost more, but makes your memory a lot more reliable. Mostly used in database or file servers, It reduces the number of crashes due to memory data corruption.

On Linux, you can check the physical chip information with `dmidecode` - type 17 is memory device

![image](https://user-images.githubusercontent.com/72258375/147559741-46e49dd1-94dc-4c27-8843-e8bc19d0f7be.png)


If you are not happy with DDR memory, you can upgrade to *HBM* memory. They will be able to handle ~ 300 GB/s but they do not come cheap.

## Virtual memory

### Definition

As system becomes more greedy in memory usage and RAM becoming more scarce, Linux had to think about ways to make the system reproduce RAM virtually.

Virtual memory is using a disk as an extension of RAM, so the effective size of usable memory grows correspondingly.

Of course, reading and writing on the hard disk is thousand times slower than using physical memory, but with the rise of SSD, this technology is becoming more and more efficient.

The part of the hard disk used as virtual memory is called *swap space*. It can be a normal file or a separate partition (recommended).
While using a file allows for more flexibility, as you dont need to reformat it, the current standard is to use LVM data partition together with a swap partition.

Like so:

![image](https://user-images.githubusercontent.com/72258375/147560231-ba32b5b6-3fa8-433a-848c-e451db107550.png)

Linux memory management is responsible for :
- Implementation of virtual memory
- Demand paging
- Memory allocation both for kernel internal structures and user space programs
- Mapping files into processes address space
- and much more !

*Note* Swapping means writing the whole process out to swap space, while paging is writing only fixed size parts (a few kb) and is more efficient.

### Buffering

_Shared_ memory is when multiple process use the same memory block.

_Buffers/cache_ represents the disk buffer cache.

As reading from a disk is very slow compared to physical memory, It is common to save commonly accessed data onto the memory until no longer needed.
It speeds up all but the first read (when you first access it on the disk), and It is called *disk buffering* while the memory used for this purpose is called *buffer cache*

If this buffer cache is full, the data unused for the longest time is discarded first to free up some memory.

This is important as this disk buffering works for writes as well, and is the cause of lost data when the system crash as It has no time to save it onto the disk.

You can force this write with _sync_ or _bdflush_ (automatic on Linux every 30 seconds)

![image](https://user-images.githubusercontent.com/72258375/147561561-06de508c-2ed2-4a96-b707-13575dc3795d.png)

This cache size is automatically set by Linux and is usually made up of all free RAM. It decreases in size when memory is needed for greedier process.

### Paging

Physical memory is not necessarily contiguous, It can be accessible as a set of distinct adress ranges. All this makes dealing directly with physical memory quite the hassle and to avoid this complexity a concept of virtual memory was developed.

Paging is the bridge between this virtual and physical address. 
Each time a software requires to write, the virtual memory only share the needed information in the physical memory (*demand paging*), while providing a mechanism for protecting and controlling sharing of data between processes.

Each physical memory page can be mapped as one or more virtual pages, and these mappings are described by page tables to allow translation from a virtual to physical memory address.

You can check this table in _/proc/meminfo_

![image](https://user-images.githubusercontent.com/72258375/147562696-ec9bad53-128c-4d96-84ca-7d5aeb054a00.png)

To avoid using CPUs for each address translation, modern architecture use a TLB or *T*ranslation *L*ookaside *B*uffer, to keep this information cached.

We could dive deeper in the subject, but we just need to know this created the concept of _Huge page_ which is mapped by either _TLB_ or _THP_

![image](https://user-images.githubusercontent.com/72258375/147563280-29aa9ade-2331-4ada-a543-da66f46f71ba.png)


### Commands

To know your memory, you can check with *free*

![image](https://user-images.githubusercontent.com/72258375/147555688-ea9ccbc5-db92-4dbc-ad82-dd1f1002ff2e.png)

It will print you informations about your memory usage, notice how Swap is included, although It's written on disk. 
RAM is usually called *physical* memory.

This information is polled from _/proc/meminfo_ ; but some others informations are available in _/sys/devices/system/memory/_

![image](https://user-images.githubusercontent.com/72258375/147556284-e4effdf6-44be-4683-9d8f-d841480ec3ab.png)

We can test this memory usage with several command:
```
cat /dev/zero |head -c 5G | tail
tail /dev/zero
cat <( </dev/zero head -c 500m) <(sleep 5) | tail
```

Let's try to fill out memory and swap space ! First we fill our physical memory (8G) and swap (5G) with 10G of data.

![image](https://user-images.githubusercontent.com/72258375/147563890-6f3f42bf-449c-47cc-b477-ef9042b150cd.png)

then we check our memory is used with _top_:

![image](https://user-images.githubusercontent.com/72258375/147563950-5dd25179-fc08-4381-885f-7c6eb28ee33f.png)

or with _free_

![image](https://user-images.githubusercontent.com/72258375/147564005-a15422ef-7992-41f2-b242-4631d8cc4a18.png)

And after we stop it, we are back to normal:

![image](https://user-images.githubusercontent.com/72258375/147564037-bdbaa83b-c23b-4223-8b81-d5b101891f63.png)

You can also look into _pv_ command to have an overtime change on RAM (whether in rate/sec or minutes)

## Storage

Now that we have seen how physical and virtual memory interacts, we will dive into long-term memory, the one that stays after each reboot.

### Definition

Linux storage is based on block devices, providing buffered access to the hardware. 
While there is multitude of storage solutions now, whether they are cloud based, an external device or internal, they all share the same objective: storing data.

It can used to save files, run tasks and applications, and today came to be in gigabytes or terabytes capacity.

We will not cover USB flash drive, optical storage such as Blu-Ray discs, as there are decreasingly useful with the advent of mobile phones and cloud solutions.

### Different types of storage

#### Hard-drive

An HDD (*H*ard *d*isk *d*rive) is a hard drive that uses mechanical spinning disks using a magnetic tip to read and write data.
HDDs are considered as the most reliable data storage hardware in most servers, the main appeal to get them are their cheap cost compared to their capacity, although they are slower than others solutions.

They are often called SATA drive, as this is the name of the computer bus interface that connects them to the motherboard.
It's not wrong to say that, but SSDs can also be connected to the motherboard through the SATA interface.
To bring a few words on SATA, there is today others solutions like Thunderbolt, SCSI, NVMe. SATA has 3 versions (I II III), going from 150 MB/s, 300 MB/s to 600MB/s, however [most hard-drive are unable to beyond 150 MB/s speed](https://hdd.userbenchmark.com/).

This is the reason why SATA drive are an idiom for hard-drive disk, even though SATA III could handle some SSD speed.

Server hard drive works 24/7/365, and usually comes in with a [3-5 years warranty](https://www.seagate.com/fr/fr/products/hard-drives/barracuda-hard-drive/). This makes them way more pricer, but manufacturer often categorize them into three:
- ECO - consumer-grade hard-drive
- BC - pro-grade hard-drive
- EP - server-grade hard-drive

These hard-drives have differents requirements, for reliability, recovery and speed. Most benchmark will try to compare their sequential and random write and read speeds, but price and capacity should be equally considered. There is never too many HDDs.

#### SSD

While HDDs are mechanical disks, SSD are flash storage and are much faster (boot time is 10s). They are more expensive, and data recovery can be complicated. It is however easier to transport (no moving parts), and consume less power. Most manufacturers are now focusing primarly on SSDs instead of HDDs.

SSDs are usually limited to their bus speed, in case of SATA III at around 450 MB/s sequential speed making them 3 times faster than HDDs. For comparaison, USB3 has transmission speed up to 600 MB/s while USB2 are limited to 50 MB/s.

This is the reason why most SSDs are now connected through PCIe (3.0 or 4.0) or NVMe, as they are able to scale way better. 

*PCIe* depends on their version (currently from 1 to 6) and their number of channels. x16 being the usual amount.

| PCIe version | PCIe x16 speed (GB/s) |
| --- | --- |
| 1.x | 4 |
| 2.x |  8 |
| 3.x |  16 |
| 4.x |  32 |
| 5.x |  63 |
| 6.x |  126 |

With SSD, going from SATA to PCIe-6-x16 (which comes out next year), would make it go 210 times faster. Of course, you would be then limited by your RAM or CPU speed.

*NVMe* is a communication interface standing between your CPU and your storage interface using PCIe sockets. It was solely designed for SSD. While there is a few SSDs format, such as _2.5"_ or _mSATA_, the only one compatible with _NVMe_ version are _M.2_ and _U.2_. Main differences between these last two formats is U.2 allows for hot-swap, you can add them during your system runtime.

If you are still not satisfied with this, check out [Optane](https://www.intel.com/content/www/us/en/products/details/memory-storage.html).

### Cool commands

Now that we understand the different types of storages, Linux allows us to check their health through a few commands

You could use _df_ to report file system disk space usage. But It doesn't show you your physical hard drives.

![image](https://user-images.githubusercontent.com/72258375/147573437-3f596eec-d04f-40a6-8a72-b0cb93b4c0b0.png)

If you are more interested in which files takes the most space, _du_ is your tool:

![image](https://user-images.githubusercontent.com/72258375/147573846-19df5e37-cc62-4968-86d0-10cccd9426fb.png)

More focused on drives ? Use _fdisk_ ir _lsblk_:

![image](https://user-images.githubusercontent.com/72258375/147573963-735d9d77-ef88-4401-a49c-ab9ec63dd78a.png)

![image](https://user-images.githubusercontent.com/72258375/147574214-0e2f09bf-dca3-450e-bef3-5f116bb0ad89.png)


Oh you meant actual hardware informations on those disks ? Use _lshw -class disk_

![image](https://user-images.githubusercontent.com/72258375/147574181-3a3c7b38-935f-451c-b023-87c814e4859c.png)

If you want to dive deeper, you might want to check out the available informations in _/dev/disk_ where you can sort by:

![image](https://user-images.githubusercontent.com/72258375/147574278-8cefe57d-a024-452a-bf1a-119423b9993a.png)

or in _/sys/block_

![image](https://user-images.githubusercontent.com/72258375/147574318-ccb69a01-5b6d-4413-8bb1-362d247f6e3d.png)


## To go further

If you are running another OS, check out [rosetta](http://bhami.com/rosetta.html) to help you find the right commands.

There was a lot to cover on this one, but I learned a lot on the virtual memory and bus interface, so all worth it !


> Credits
> 
> https://thewiredshopper.com/ddr3-vs-ddr4-vs-ddr5/
>
> https://en.wikipedia.org/wiki/ECC_memory
>
> https://0xax.gitbooks.io/linux-insides/content/Theory/linux-theory-1.html
>
> https://tldp.org/LDP/sag/html/buffer-cache.html
>
> https://www.kernel.org/doc/html/latest/admin-guide/mm/concepts.html
> 
> https://www.redhat.com/sysadmin/dissecting-free-command
