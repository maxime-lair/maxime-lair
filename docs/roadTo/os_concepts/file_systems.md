# File systems

In this article, we will dive into the linux file systems, from the different format, its structure, the file types and some facts about partitions and mounts.

_My lab is running on a Centos 9 Stream, which came out this very month. Most of this will apply to Linux distribution, I will not cover Unix or Windows command._

## Definition

[From TLDP: ](https://tldp.org/LDP/intro-linux/html/sect_03_01.html) A simple description of the UNIX system, also applicable to Linux, is this:
> "On a UNIX system, everything is a file; if something is not a file, it is a process."

This statement is true because there are special files that are more than just files (named pipes and sockets, for instance), but to keep things simple, saying that everything is a file is an acceptable generalization. A Linux system, just like UNIX, makes no difference between a file and a directory, since a directory is just a file containing names of other files. Programs, services, texts, images, and so forth, are all files. Input and output devices, and generally all devices, are considered to be files, according to the system.

In order to manage all those files in an orderly fashion, man likes to think of them in an ordered tree-like structure on the hard disk, as we know from MS-DOS (Disk Operating System) for instance. The large branches contain more branches, and the branches at the end contain the tree's leaves or normal files. For now we will use this image of the tree, but we will find out later why this is not a fully accurate image.

This way of thinking in tree is redundant in OOP (Metholds are held by Class that implements Interfaces), blockchain or version control (Git branches).

## Different file system

Before storing any data on your file system, your storage device must first be formatted to a type understood by the operating system. There is too many formats to name them, but we can start with the most popular ones:
- F2FS
- Ext4
- XFS
- Btrfs

They all have their perks and defaults (stability, performance, OS support, etc.), you will use one depending on your usecase, there is bad and good answers as long as they are reasoned.

We can check our own file format with _fdisk_
![image](https://user-images.githubusercontent.com/72258375/147471121-a6ec7d62-6f12-4a1f-8a94-593fc6b8199a.png)

And check on a specific partition which format to use is available:
![image](https://user-images.githubusercontent.com/72258375/147471518-f4a7f725-5418-4484-b9d4-a22f1ec6aaf3.png)

### Flash media (F2FS)

Without diving too deep, all you need to know is there is two types of flash memory: NOR and NAND logic. They share the same cell design, but are connected differently, which makes NOR able to random access and NAND restrained to page access. This makes NOR 60% physically larger than NAND flash. As a result, NOR is better for reading but worse for storing data, while NAND is quick at writing but less endurant.

Now that you know that, you will understand why a specific file system format is better for some storage device than others.

Let's say you have a NAND flash memory-based storage devices like a SSD or SD Card. It is not surprising as they are becoming the most used storage device for servers and mobile devices due to their speed, noise and reliability. From what we just learned, they are quick to write into, but last less time. Can we use a file system that address their issues while supporting its strenghts ?

That's what Samsung did with _F2FS_, but It is hard to predict if they will become the most common fs for flash devices.

### Ext4

This filesystem format stands for __Extended File system__ and It is the default one in recent Linux. It is backwards compatible with former iterations (ext3, etc.) and useable in Windows 10 since 2016 and macOS through extFS.

It released in 2008 and has stood as one of the most used file system format for more than a decade now. Google is one of their main users since 2010. This is why It is the default format for android phones today. My (humble) guess is ext4 will slowly decline to make room for more modern file systems format.

It supports up to 1 Exabyte volumes (1000 To) and file size up to 16 Terabytes (TB).

### XFS

This format will probably become overthrow ext4, as It was built for performance and is mainly used on storage that are constantly reading and writing data.

To compare it with ext4, XFS supports up to 16 Exabytes volumes and 8 Exabytes file size (i.e. 16 times larger and 500 times larger than ext4). It also is optimized for quicker crash recovery thanks to its metadata journaling.

It is supported by most operating systems, and can be used in google cloud for _container-optimized OS_.

### BtrFS

As the last file system format we check, with previous ones focused on flash, wide-support and performance, we will study one mainly used for long-term storage (for NAS, etc).

It includes snapshots and self-healing mechanisms. Facebook is one of their users, much like Parrot project and Trupadvisor. It is the least popular ones among the four, as It is one of the most recent (~ stable as of 2013). As soon as people starts to use it and understand the snapshot perks, It might gain more traction in the future.

## Linux file system structure

Now that we have seen some filesystem format, we can focus on the linux file system structure.

Once you decide on F2FS, ext4, XFS or BtrFS format, linux will build its directory tree. It is defined by the _FHS_ (Filesystem Hierarchy standard) but It is a "trailing standard" for most distributions.

For example, all Linux distribution share the same root directory called `/` and essentials binaries needed in single-user mode are located in `/bin`. But they don't all possess a `/run` directory.

In CentOS 9:

![image](https://user-images.githubusercontent.com/72258375/147477010-0e707d11-3fde-49bf-9349-33a41b3eed89.png)

*Note* All symlink (bin, sbin, lib, lib64) points to `/usr` 

Let's check each subdirectories, and understand what type of files we could find there

### /bin



### /boot

### /dev

### /etc

### /home

### /lib

### /media

### /mnt

### /opt

### /proc

### /root

### /run

### /sbin

### /srv

### /sys

### /tmp

### /usr

### /var


## File types


### Regular file

### Directory

### Link

### Special file

### Socket

### Named pipe

### Block device



## Partitions

### Data partition


### Swap partition


## Mounts


## To go further

Each filesystem format has their own implementations, and could be interesting to check at a low-level. We could perform a write/read tests to check which ones are more performant. 

There is a lot of commands available to play with files in Linux, and they will be covered in a later article.

Check out some links below to dive deeper into the subject.

> Credits
>
> https://linuxiac.com/linux-file-system-types-explained-which-one-should-you-use/
>
> https://www.linux.com/training-tutorials/linux-filesystem-explained/
>
> https://opensource.com/life/16/10/introduction-linux-filesystems
>
> https://tldp.org/LDP/intro-linux/html/sect_03_01.html
>
> https://en.wikipedia.org/wiki/Flash_memory
>
