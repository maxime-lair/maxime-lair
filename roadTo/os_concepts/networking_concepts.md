# Networking concepts

In this article, we will try to focus on the layer 2 and 3 of the OSI model.

We will try to understand IP v4/v6 works without diving too much into details, and understand how It is routed across networks.

We could also call it understanding the network layer, as we will cover *ARP/ICMP/MAC/LLC*

We will however not dive into TCP/UDP specifics, as It would make the article too clustered with informations, and It was already partly covered in the [sockets](sockets) article

## Datalink layer

This layer transfers data between nodes on a network segment (often *Ethernet*) across the *physical layer* (the electronic circuit). It may also detect and possibly correct errors that can occur in the physical layer. It is concerned with the local delivery of **frames**.

A **frame** do **not** cross the boundaries of a local area network. Inter-network routing and global addressing are higher-layer functions. You could compare the datalink layer to a [roundabout](https://en.wikipedia.org/wiki/Roundabout), It arbitrates parties for access to a medium without concern for their ultimate destination.

*Frame collisions* occur when devices attempt to simultaneously use the same medium (e.g. a traffic crash). Data-links protocols try to detect, reduce, prevent and recover from such collisions.

The main protocols are:
- Ethernet
- Point-to-Point (PPP)
- HDLC
- ADCCP

### Ethernet 802.xx

**TODO**

### Alternatives

#### Point-to-point

#### HDLC

#### ADCCP

### LLC/MAC

The data link layer is often divided into two sublayers:
- Logical link control (LLC)
- Media access control (MAC)

#### LLC

The uppermost sublayer multiplexes protocols running at the top of the data link layer, It makes it possible for several network protocols to coexist within a multipoint network and to be transported over the same network medium. It also provides addressing and control of the data link. It can be considered as the interface between the network layer and the MAC. In short, the LLC provides a way for the upper layers to deal with any type of *MAC* layer.

It can also optionally provide flow control and error management capabilities, but It depends on the protocol stack, as It can be taken care of by a transport layer such as TCP.

In Ethernet, bit errors are very rare in wired networks, receiving incorrect packets will simply be detected and dropped, but not retransmitted (It will expect higher layer to do it).

In Wireless communications, bit errors are very common, but the flow control and error management is handled by the MAC layer through *CSMA/CA*, and is thus not part of the LLC layer.

![LLC_PDU](https://user-images.githubusercontent.com/72258375/151045484-ec903706-6599-4495-8cb6-1a8b43ea7bfb.png)

Note the control part can be either 8 or 16 bits long depending on the format (mostly 8 bits). We will not dive into the specifics, as It is rarely a source of bug, as you can see It is mainly to indicate the service access port.

This unit is then followed by a multiple of 8 bits, containing the **information** of the upper layer data.

But this model is rarely used in reality, and TCP/ARP frames will not use the SAP value for *TCP/ARP*, but will use *SNAP* instead. SNAP is an extension of the LLC, by adding 40 bits after the LLC header. SNAP supports identifying protocols by Ethernet type field values; it also supports vendor-private protocol identifier spaces instead of being limited to the 7-bit identifying code.

![LLC_PDU_SNAP(1)](https://user-images.githubusercontent.com/72258375/151050049-090f681a-2668-4304-b7fe-a0aad2299ea6.png)

If the OUI value is *zero*, the protocol ID is the registered [*EtherType*](https://en.wikipedia.org/wiki/EtherType)

This is why, on Ethernet, the 8 octets (3 from *LLC*, 5 from *SNAP*) reduce the size of the available payload such as IP to 1492 bytes (from the default MTU 1500). Therefore, with protocols that have EtherType values, packets are usually transmitted with Ethernet II headers rather than with LLC and SNAP headers, but on other network types, the LLC and SNAP headers are required in order to multiplex different protocols on the link layer, as the MAC layer doesn't possess an EtherType field, so there's no alternative framing that would have a larger available payload.

For example, IP datagrams and ARP datagrams are transmitted over IEEE 802 networks using LLC and SNAP headers.

### MAC layer

Also called the medium access control sublayer, It controls the hardware responsible for interaction with the transmission medium (wired, optical or wireless). While the LLC provides flow control and multiplexing for the logical link (EtherType, etc.), the MAC provides flow control and multiplexing for the transmission medium.

It includes a local network address called MAC address, intended to be a unique serial number assigned by the network interface hardware (NIC) at the time of manufacture. It is 48 bits long, separated by colons every two digits

An example, this one belongs to *Samsung Electronics*:

![MAC_48(3)](https://user-images.githubusercontent.com/72258375/151060330-1d0d3833-c5c9-450d-882c-3c7f4aa9394d.png)

a MAC address can be defined universally by the manufacturer or locally by a system administrator. MAC address are by definition finite and we will end up running out of possible addresses, so an alternative called **EUI** was created. It simply adds 2 octets to the *UAA*, all *MAC-48* are *EUI* by padding `FF:FF` between your OUI and UAA.

![EUI_64](https://user-images.githubusercontent.com/72258375/151061413-784317f2-a632-4169-9881-88ab246ef8f7.png)

Ethernet frames with a value of 1 in the least-significant bit of the first octet of the destination MAC address are treated as multicast frames and are flooded to all points on the network. 

Some blocks are reserved to specific usage, such as PTP (Time precision protocol) or STP (Spanning tree protocol), you can check them [here](https://en.wikipedia.org/wiki/Multicast_address). These blocks are either only on Local LAN link or either be forwarded through bridges.

Easier to understand with an example:

![MAC_48_multicast](https://user-images.githubusercontent.com/72258375/151064299-bdeaeebd-e5b0-4965-be16-90067188e9d8.png)

The MAC protocol is used to provide the data link layer of the communication protocol (e.g. Ethernet), and its header include 16 bytes with a CRC at the end:

![MAC_header](https://user-images.githubusercontent.com/72258375/151067888-427a5afe-daac-4e1b-bd4e-2210a75ab487.png)


### Switch/Bridge/WAP

## Network layer

Organize frames into packets (fragmentation + reassembly), and decide on path from source to destination

### IPv4

### IPv6

### ARP

### ICMP

## Useful commands and utilities

### IP command

### /proc

### /sys

## Conclusion


> Credits
>
> https://en.wikipedia.org/wiki/Subnetwork_Access_Protocol
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
