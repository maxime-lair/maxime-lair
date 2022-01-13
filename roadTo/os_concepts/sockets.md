# Sockets

Here we will study the different sockets available and how they function. We will try to implement some, and check the latency between local socket and multi-host ones.

## Definition

Operating systems include the BSD interprocess communication facility known as *sockets*. They are communication channels that enable unrelated processes to exchange data *locally and across networks*. The Berkeley sockets API represents it as a file descriptor (file handle) in the Unix philosophy that provides a common interface for input and output to streams of data. Berkeley sockets evolved with little modification from a de facto standard into a component of the POSIX specification. The term POSIX sockets is essentially synonymous with Berkeley sockets, but they are also known as BSD sockets.

A *socket* uniquely identifies the endpoint of a communication link between two application ports. A socket is typically representated through five informations:
- The domain
- The type
- The protocol
- The hostname
- The port

This [quintuple](https://en.wiktionary.org/wiki/quintuple) is used to correctly identify a socket on a host. This host will add this socket to its local table by associating it with a socket descriptor (an integer).

While a socket is mostly used over a network to allow two hosts to communicate between each other, communication between local processes (e.g. IPC) also makes use of socket. They separate into a few different family, or domain:
- AF_UNIX for UNIX domain family, also called IPC socket
- AF_INET for IPv4 Internet socket
- AF_INET6 for IPv6 Internet socket

The behaviour is similar, but in IPC socket, rather than using an underlying network protocol, all communication occurs entirely within the OS kernel. There is many more socket families existing, but they are often used for very specific use-case, such as Bluetooth, or virtual machine to host. *AF* stands for *Address family* while *PF* stands for *Protocol family* [if you are wondering](https://stackoverflow.com/questions/6729366/what-is-the-difference-between-af-inet-and-pf-inet-in-socket-programming). *AF* refers to addresses from the internet (e.g. IP), while *PF* can refer to anything in the protocol, usually socket/port.

Sockets are classified according to communication properties. Each socket has an associated type, which describes the semantics of communications using that socket. Each socket type incurs different properties such as reliability, ordering and session control. The most common ones are :
- Stream socket
- Datagram socket
- Raw socket
- Unix domain socket

Then, the socket has to support a protocol to allow data exchange through a standard set of rules such as UDP or TCP over IP.

I wrote a simple script in Python3 to showcase the different family/type/proto used by each socket. The choice of Python3 is arbitrary, I could have used any languages with a `socket` library (almost all). My point here will be to use this to create a client in **Python**, and a server in **Go**, to showcase that It is language-agnostic.

The code:

![image](https://user-images.githubusercontent.com/72258375/149200915-8df6fd4e-d2fc-4a49-88c7-cc93bf9c4c12.png)

The output:
![image](https://user-images.githubusercontent.com/72258375/149201355-a6776d9c-f123-4e87-8467-9fc6ef95c149.png)

We will go through each socket type, and implement a simple client/server at the end. Different protocols will be used and shortly explained, as this is the subject of another article (i.e. *networking concepts*).

## Socket creation

Sockets by themselves are not particularly useful. The purpose of a socket of course is to communicate with other sockets. In order to create a socket that is able to communicate, you must follow a few mandatory steps.

The most common relationship between two sockets on remote machines is that of **a server and a client**. The server sockets waits in an open state (*Listen*) for a client to communicate with it. Or perhaps It broadcasts messages so any clients that listening will receive it.

First, we need to create this socket with a specific communication profile. It usually follow the following pattern

![client_server(1)](https://user-images.githubusercontent.com/72258375/149205313-c9bc8b0b-cae1-4bb9-b0c9-f6ac20523390.png)

As you can see, the server should start before the client, and be in an **Accept** state before exchanging data. On the client side, It has to match the family/type/protocol in order to match the connection. At the end, the client or the server can decide on closing the exchange, but the server still has to stop itself afterwards (since there could have been other clients).

In an Internet socket, the address would be an IP/Port, but on an IPC, the address would be local, so a file system node.

## Socket types

Here we will check the different type of socket type available to us. There is a few to know, mainly in order to implement TCP/UDP and IPC.

### Stream socket

**Connection-oriented sockets**, which use *Transmission Control Protocol* (TCP), *SCTP* or *DCCP*. A stream socket provides a **sequenced and unique flow of error-free data** without record boundaries, with well-defined mechanisms for creating and destroying connections and reporting errors. A stream socket transmits data **reliably**, **in order**, and with **out-of-band** capabilities. On the Internet, stream sockets are typically implemented using TCP so that applications can run across any networks using TCP/IP protocol.

This is the most used type of socket today, as It ensures what the server send will be received in the same sequence on the client. Imagine watching a movie, you would not want the image to stutter and miss frames every few seconds, so you prefer waiting for it to buffer reliably and watch it later.

They are represented by the family/type: **AF_INET**/**SOCK_STREAM**

### Datagram socket

**Connectionless sockets**, which use User Datagram Protocol (UDP). Each packet sent or received on a datagram socket is individually addressed and routed. Order and reliability are not guaranteed with datagram sockets, so multiple packets sent from one machine or process to another may arrive in any order or might not arrive at all. Special configuration may be required to send broadcasts on a datagram socket. In order to receive broadcast packets, a datagram socket should not be bound to a specific address, though in some implementations, broadcast packets may also be received when a datagram socket is bound to a specific address.

**UDP sockets** do not have a established state. A UDP server process handles incoming datagrams from all remote clients sequentially through the same socket. UDP sockets are not identified by the remote address, but only by the local address.

This is a less reliable type of socket, but It focuses on delivery speed. If you already have a protocol on higher OSI layer that implements session and reliability, then **UDP** could be considered. Whenever there is a high bandwidth requirement, or you need to implement **multicast**, you can consider this socket type. In case of weather data for example, you do not care if you miss out on a few seconds data, but you care to receive it as fast as possible to prepare for a storm or earthquake.

They are represented by the family/type: **AF_INET**/**SOCK_DGRAM**

### Raw socket

Provides access to internal network protocols and interfaces. This type of socket is available only to users with root-user authority. Raw sockets allow to have direct access to lower-level communication protocols. Raw sockets are intended for advanced users who want to take advantage of some protocol feature that is not directly accessible through a normal interface, or who want to build new protocols on top of existing low-level protocols.

Raw sockets are normally datagram-oriented, though their exact characteristics are dependent on the interface provided by the protocol. Raw sockets are typically available in network equipment and are used for routing protocols such as IGRP and OSPF, and for Internet Control Message Protocol (ICMP).

They are usually available in most family, as one type, and they have no preferred protocol.

### Unix domain socket

Also called **Inter-process communication socket** (IPC), they are a data communications endpoint for exchanging data between processes executing on the same host operating system. While they do not implement TCP/UDP/IP as they are not over the network, they still include stream/datagram sockets capabilities. They are a standard component of *POSIX operating systems*.

Available on the **AF_UNIX** family, the *SOCK_STREAM* socket type provides pipe-like facilities, while the *SOCK_DGRAM* and *SOCK_SEQPACKET* socket types usually provide reliable message-style communications.

As a more pratical example, we can use `nc` command to create them on the fly. As you can see, the address is simply the path on the filesystem.

![image](https://user-images.githubusercontent.com/72258375/149359328-ff07ae16-816e-4b2a-8cd3-bc2e2fd8df82.png)

![image](https://user-images.githubusercontent.com/72258375/149359366-76f1a06d-8bd6-4575-b84b-9b50e325f53a.png)

It allows for a two-way communication (so by default a stream socket), be careful when creating them through this command, as It doesn't destroy the socket file afterwards.

![linux_socket](https://user-images.githubusercontent.com/72258375/149359973-1e0ec348-d9e3-471c-a8ed-e90dd0c97e64.gif)

*Note:* Named pipes are another mean of IPC within a Unix host, but they are only allow uni-directonial communication and can not distinguish clients from each other. UNIX socket are often considered a cleaner way for process to communicate between each other. 

## Socket protocol

Now that we have seen the different socket families (Unix, Internet IPv4, IPv6..), and socket types (Stream, datagram, raw, etc.), we can dive in the last part: the socket protocol.

A *protocol* is a standard set of rules for transferring data, such as UDP/IP and TCP/IP. The protocol has to be supported by the socket type (and by the socket family) to be used. While in most cases, the protocol will be automatically decided depending on the socket type (INET/Stream -> TCP ; INET/Datagram -> UDP), It is not always the case. Here is a few major protocols in the suite of Internet Network Protocols:
- TCP
- UDP
- RDS
- IP
- ICMP

### UDP

Without diving too far in the OSI layer, know those protocols stands on the *transport* layer, on top of the *network* that implements IP.

It is connectionless, offers datagram services but less reliable. While It is less popular than TCP, It is gaining traction through big scale stateful UDP services, such as [QUIC](https://blog.cloudflare.com/quic-version-1-is-live-on-cloudflare/).

UDP sockets can be either :
- *connected* containing
  - Source IP / Port
  - Destination IP / Port  
- *unconnected*
  - Bind IP / Port

An example with code, to ping Cloudflare DNS server with UDP packet:

![image](https://user-images.githubusercontent.com/72258375/149408742-b3a0540c-9037-4612-9606-fd6dbd0de98d.png)

And It will timeout as the DNS server can not answer the request:

![image](https://user-images.githubusercontent.com/72258375/149408864-07b12a47-e9a5-4a6e-bf44-78025c883b18.png)

As you can see, *connected* is great if you already know where you are going, but *unconnected* would be more fit for a server, as one socket can make multiple outbound queries.

However, UDP requires a bit more tuning when used, as **TCP** can transparently deal with MTU/fragmentation (e.g. with jumbo frames) and ICMP errors, while **UDP** might require extra care on those corner cases.

The UDP packet header:

![udp_header](https://user-images.githubusercontent.com/72258375/149413924-80fb3d86-e356-4a60-8d1a-8620e6806df0.png)

### TCP

TCP provides reliable stream delivery of data between Internet hosts.

Like **UDP**, **TCP** uses the *Internet protocol (IP)* to transport data, and supports the block transmission of a continuous stream of datagrams between process ports. **TCP** ensures that data:
- is not damaged (checksum)
- lost/duplicated (sequencing)
- delivered out of order (acknowledgement)

The packet header looks like this:


https://www.ibm.com/docs/pl/aix/7.1?topic=protocols-transmission-control-protocol

https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_for_real_time/7/html/reference_guide/chap-sockets
TCP_NODELAY
TCP_CORK


TCP_PACKET


### GRPC

## Interact with socket

### Useful commands

netstat -a -p --unix

ss

### Monitoring

/proc /sys etc

## Conclusion

> Credits
>
> https://www.ibm.com/docs/en/zos/2.2.0?topic=functions-socket-create-socket
>
> https://www.digitalocean.com/community/tutorials/understanding-sockets
> 
> https://www.ibm.com/docs/en/zos/2.2.0?topic=concepts-tcpip
> 
> https://www.ibm.com/docs/pl/aix/7.1?topic=concepts-sockets
> 
> https://ipfs.io/ipfs/QmfYeDhGH9bZzihBUDEQbCbTc5k5FZKURMUoUvfmc27BwL/socket/services.html
>
> https://blog.cloudflare.com/everything-you-ever-wanted-to-know-about-udp-sockets-but-were-afraid-to-ask-part-1/ 
