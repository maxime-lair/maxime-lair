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
