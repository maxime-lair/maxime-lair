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
 
#### IEEE 802
Here we will talk about the IEEE 802 local lan networks, with MAC layers such as Ethernet, Token Ring and 802.11 (Wireless Lan).

The **IEEE 802** is restricted to computer networks carrying variable-size packets, unlike cell relay networks (e.g. ADSL). It is a group of standards for LANs, numbered 802.1 to 802.12, with the most important ones being:

| Number | Description |
| --- | --- |
| 802.3 | Ethernet |
| 802.8 | Fiber optic |
| 802.11 | WLAN |

> Note: the number 802 has no significance: it was simply the next number in the sequence that the IEEE used for standards projects.

Over the years, a few numbers were added for specific case, such as *802.15* for Wireless Personal Area Network (WPAN) and *802.15.6* for Body Area Network (BAN) used for peacemaker or body implants devices.

#### Ethernet

Ethernet is a family of wired computer networking technologies, and has largely replaced competing wired LAN technologies such as *Token Ring* or *FDDI*. It can go up to 400 Gbit/s and is currently developping a 1.6 Tbit/s rate as of 2021.

Systems communicating over Ethernet divide a stream of data into shorter pieces called **frames**. Each frame contains source and destination addresses and error-checking data. This address is defined as the MAC address and is used by other IEEE 802 networking standards such as 802.8 (FDDI) or 802.11 (Wi-Fi).

It is the one of the foundation that make up the Internet, as the IP is commonly carried over Ethernet. Most Ethernet devices use twisted-pair cables for the physical layer, as opposed to coaxial cable. While coaxial support greater cable lengths (200+ meters) compared to twisted pair (100 meters maximum), twisted pair is less expensive and allows speed up to 100 Gbps (Depends on cable category, 5 being standard, 8 used in datacentre).

The ethernet frame:

![ethernet_frame(1)](https://user-images.githubusercontent.com/72258375/151184038-c201f7f9-8c27-40a6-900f-910c8983d54b.png)

One notable frame structure of Ethernet frame is having no *time-to-live field*, which can lead to a switching loop (also known as **broadcast storms**). This can happen If there is more than one layer 2 path between two endpoints (connecting two ports on the same switch to each other), multicasts are then repeatedly forwarded forever, flooding the entire network. We will see how to avoid this in a later section.

While Ethernet frames are usually 1518 bytes long, they can potentially appear smaller or bigger depending on the system settings. A larger ethernet frame is called **Jumbo frames** and can go up to 9000 bytes long  (or you can go further and beyond with **Super jumbo frames** going up to 64000 bytes). If this size is non-uniform to a network node, It will be detected as **Jabber** and subsequently dropped. On the opposite, an Ethernet frame has a minimum size of 64 bytes (18 bytes header and 46 bytes payload), anything smaller is considered **Runt frames** and is subsequently dropped.

### Alternatives

In the data-link layer, while the IEEE 802 is often used, a few alternatives exist to perform the same function. It often depends on the network hardware used to transmit data on the physical layer.

#### Point-to-point

*PPP* is a data link layer communication protocol between two routers directly without any host or any other networking in between. It was designed to work with numerous network layer protocols such as IP or IPX. *PPP* is used over many types of physical networks such as phone line, ISDN. Your Internet Service Provider (ISP) could have used *PPP* to establish a connection through the facilities of the public switched telephone network.

It can provide *authentication* through password or challenge handshake, *compression* and *error detection*. It is often used whenever you need to tunnel data over IP networks, as a tunnel is by definition a point-to-point connection and PPP is thus a natural choice between the virtual network interfaces. PPP can assign IP addresses to these interfaces that can be used to route between the networks on both sides of the tunnel. These interfaces would be called **tun0** or **ppp0**.

In case of VPN (e.g. IPSec in tunneling mode), no virtual network interfaces are created, since the tunnel is handled by the transport layer (TCP/IP), and **L2TP** is then used, but here *PPP* also provides IP addresses to the extremities of the tunnel.

#### ADCCP / HDLC

Previously used data link layer protocol which was bit oriented. they are both functionally equivalent, and most currently used protocols in the datalink layer were derived from their specifications. It was progressively less used due to Ethernet popularity.

### LLC/MAC

The data link layer is often divided into two sublayers:
- Logical link control (LLC)
- Media access control (MAC)

#### LLC

The uppermost sublayer multiplexes protocols running at the top of the data link layer, It makes it possible for several network protocols to coexist within a multipoint network and to be transported over the same network medium. It also provides addressing and control of the data link. It can be considered as the interface between the network layer and the MAC. In short, the LLC provides a way for the upper layers to deal with any type of *MAC* layer.

It can also optionally provide flow control and error management capabilities, but It depends on the protocol stack, as It can be taken care of by a transport layer such as TCP.

![LLC_PDU](https://user-images.githubusercontent.com/72258375/151045484-ec903706-6599-4495-8cb6-1a8b43ea7bfb.png)

Note the control part can be either 8 or 16 bits long depending on the format (mostly 8 bits). We will not dive into the specifics, as It is rarely a source of bug, as you can see It is mainly to indicate the service access port.

This unit is then followed by a multiple of 8 bits, containing the **information** of the upper layer data.

But this model is rarely used in reality, and TCP/ARP frames will not use the SAP value for *TCP/ARP*, but will use *SNAP* instead. SNAP is an extension of the LLC, by adding 40 bits after the LLC header. SNAP supports identifying protocols by Ethernet type field values (**Ethertypes**); it also supports vendor-private protocol identifier spaces instead of being limited to the 7-bit identifying code.

![LLC_PDU_SNAP(1)](https://user-images.githubusercontent.com/72258375/151050049-090f681a-2668-4304-b7fe-a0aad2299ea6.png)

If the OUI value is *zero*, the protocol ID is the registered [*EtherType*](https://en.wikipedia.org/wiki/EtherType)

An EtherType field in each frame is used by the operating system on the receiving station to select the appropriate protocol module (e.g., an Internet Protocol version such as IPv4). Ethernet frames are said to be self-identifying, because of the EtherType field. Self-identifying frames make it possible to intermix multiple protocols on the same physical network and allow a single computer to use multiple protocols together.

This is why, on Ethernet, the 8 octets (3 from *LLC*, 5 from *SNAP*) reduce the size of the available payload such as IP to 1492 bytes (from the default MTU 1500). Therefore, with protocols that have EtherType values, packets are usually transmitted with Ethernet II headers rather than with LLC and SNAP headers, but on other network types, the LLC and SNAP headers are required in order to multiplex different protocols on the link layer, as the MAC layer doesn't possess an EtherType field, so there's no alternative framing that would have a larger available payload.

For example, IP datagrams and ARP datagrams are transmitted over IEEE 802 networks using LLC and SNAP headers.

### MAC layer

Also called the medium access control sublayer, It controls the hardware responsible for interaction with the transmission medium (wired, optical or wireless). While the LLC provides flow control and multiplexing for the logical link (EtherType, etc.), the MAC provides flow control and multiplexing for the transmission medium.

#### MAC access methods

In Ethernet, bit errors are very rare in wired networks, receiving incorrect packets will simply be detected and dropped, but not retransmitted (It will expect higher layer to do it). The collision detection is these case is handled by *CSMA/CD*, *CD* meaning Collision detection.

In Wireless communications, bit errors are very common, but the flow control and error management is handled by the MAC layer through *CSMA/CA*, *CA* meaning Collision Avoidance.

#### MAC addressing

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

#### Quality of service control

https://en.wikipedia.org/wiki/Quality_of_service

#### VLANs




### Switch/Bridge/WAP

Ethernet switch -> ARP spoofing / MAC flooding -> load-balancing (SPB) / redundancy (STP)



## Network layer

Organize frames into packets (fragmentation + reassembly), and decide on path from source to destination

### IPv4

### IPv6

### ARP

### ICMP

### Nat / Masquerade

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
