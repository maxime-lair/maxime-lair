# Virtualization

In this article, we will talk about the different types of virtualization available on the market, how they are implemented and try to provide an explanation how their rise to prominence in the past 15 years. At the end, we should understand what is a virtual machine, hypervisor, container or jails and have an idea of what's coming next.

**Note** I'm using a CentOS 9 Stream (released in Dec 2021) running on an ESXi 7.0.

## Definition

Virtualization is the act of creating a virtual (as opposed to actual) version of something. It includes virtual computer hardware platforms, storage devices and computer network resources. While the term is broad, in our case It is mostly applied to a few different types, namely:
- **Hardware virtualization**
  - Full virtualization
  - Paravirtualization 
- **Desktop virtualization**
- **Operating-system-level virtualization**, also known as **containerization**

We will explore each of them, and understand their usecases and differences. There is many more types which can be applied to IT/CS, but It will be explored in other articles, to name a few (with some examples):

| Virtualization type | Example |
| --- | --- |
| Application | *Citrix XenApp* |
| Service | *Postman* |
| Memory | *AppFabric Caching Service* |
| Virtual memory | *Swap + RAM* |
| Storage | *disk partition* |
| Virtual file system | *CBFS*/*VFS* |
| Virtual disk | *.iso* |
| Data virtualization | *VDFS* |
| Network | *VLAN* / *vNIC* / *VPN* |

Before we dive in the details, we can try to explain why It rose to such popularity in the recents years. By separating resources or requests for service from the physical delivery of that service, virtualization enables owners to distribute resources across the enterprise and use infrastructure more efficiently. This has been made evident with all Cloud computing platforms such as **AWS**, **AZURE** or **GCP**. 

The rise of the service design patterns made it all the more effective under Moore's law, where computing power was rendered cheap, and [Internet bandwidth exploded](https://www.infrapedia.com/app) (through fiber or 5G networks), all to have clusters outsourced.

![image](https://user-images.githubusercontent.com/72258375/148470728-df6d6abd-35ae-4105-a83d-848acb7bdc87.png)

## Hardware virtualization

Hardware virtualization specialize in efficiently employ underused physical hardware by allowing different computers to access a shared pool of resources. There is a few components to note:
- The hardware layer, often called **host**, contains the physical server components, It can be CPU, memory, network and disk drives. It requires an x86-based system with at least one CPU
- The hypervisor creates a virtualization layer that runs between the OS and the server hardware, and acts as a buffer between the host and the virtual machines. It isolates the virtual components from their physical counterparts
- Virtual machines are software emulations of a computing hardware environment, and provide the same functionalities of a physical computer. They are often called *guest machine* and consist of virtual hardware, guest OS and guest applications

CPU virtualization emphasizes performance and runs directly on the processor whenever possible. The goal is to reduce the overhead when running instructions from the virtual layer compared to instructions on the hardware layer.  

## IOMMU infrastructure

Having a memory controller with IOMMU will speed up virtualization instructions by reducing the amount of context switch, resulting in little to no difference compared to running hardware machine. This is often advertised as **Intel VT-d** or **AMD-Vi**. IOMMU is what made it all possible. It is an unit which allows guest virtual machines to directly use hardware devices through DMA and interrupt mapping. Be careful on this, as while this is a CPU unit, It requires motherboard chipset and system firmware (BIOS or UEFI) support to be usable.

### IOMMU goal

In a virtualization environment, the I/O operations of I/O devices of a (virtual) guest OS are translated by their hypervisor (software-based I/O address translation). It results naturally in a negative performance impact.

In an emulation model, the hypervisor needs to manipulate interaction between the guest OS and the physical hardware. It implies that the hypervisor translates device address (from device-visible *virtual* address to device-visible *physical* address and back), this overhead requires more CPU computation power, and heavy I/O greatly impacts the system performance.

The next figure illustrates it:

![image](https://user-images.githubusercontent.com/72258375/148468760-6532e5b8-a19d-4dd1-b5c0-c40890d3737d.png)

Next, we get into the **pass-through** model, where the hypervisor is bypassed for the interaction between the guest OS and physical device. It has the advantage of avoiding the *emulated device and attached driver*. Here, the address translation is seamless between the guest OS and the physical device. 

The next figure illustrates it:

![image](https://user-images.githubusercontent.com/72258375/148469372-00b68542-9ace-4c2b-a1e9-c4192bd8137a.png)

It is made available thanks to a **hardware-assisted component** called *IOMMU*. And It looks more like this:

![image](https://user-images.githubusercontent.com/72258375/148470128-6ff475ae-6eef-42db-81ec-7aede56cb8f9.png)

*Note:* IOMMU is physically present inside the CPU, but It is easier to represent it like this for now.

There is two memory management units in a CPU:
- MMU (*Memory management unit*), to translate *CPU-visible virtual address* <-> *physical address*
- IOMMU (*Input output memory management unit*), to translate *device-visible virtual address* <-> *physical address*

In order to provide this feature, *IOMMU* provides two functionalities, DMA remapping and interrupt remapping.

### IOMMU DMA remapping


### IOMMU interrupt remapping



### Full virtualization


### Paravirtualization



## Desktop virtualization


## Containerization


## Conclusion


> Credits
> 
> https://www.citrix.com/fr-fr/solutions/vdi-and-daas/what-is-hardware-virtualization.html
> 
> https://en.wikipedia.org/wiki/X86_virtualization#I/O_MMU_virtualization_(AMD-Vi_and_Intel_VT-d)
> 
> https://lenovopress.com/lp1467.pdf
> 
> 
> 
> 
> 
> 
> 
> https://www.infrapedia.com/app
