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

![tcp_header_flag](https://user-images.githubusercontent.com/72258375/149421146-96f96b0d-6ded-49c9-8c0a-2bc63573733f.png)

The following are operational characteristics of **TCP**:

| Item | Description |
| --- | --- |
| **Basic Data transfer** | TCP can transfer a continuous stream of 8-bit octets in each direction between its users by packaging some number of bytes into *segments* . TCP implementation allows a segment size of *at least 1024 bytes* |
| **Reliability** | A sequence number is assigned to each octet it transmits and requiring a positive acknowledgment (ACK) from the receiving TCP. If the ACK is not received within the time-out interval, the data is retransmitted. The TCP retransmission time-out value is dynamically determined for each connection, based on round-trip time | 
| **Flow control** | TCP governs the amount of data sent by returning a window with every ACK to indicate a range of acceptable sequence numbers beyond the last segment successfully received | 
| **Multiplexing** | TCP allows many processes within a single host to use TCP communications facilities simultaneously. TCP receives a set of addresses of ports within each host | 
| **Connections** | TCP must initialize and maintain certain status information for each data stream. The combination of this information, including sockets, sequence numbers, and window sizes, is called a connection | 
| **Precedence and security** | The priority function is provided to allow TCP to mark certain packets as higher priority. Packets with higher priority will get forwarded first. In addition, a provision is made to allow for compression and encryption of the TCP headers. All of these functions are signalled by a set of flags in the TCP header |

As you can see, while the header is larger than in **UDP** case, It adds useful features for your connection. The way It operates is also different, as It is divided into three phases:
- Connection Establishment (through **three-way handshake** --> SYN + SYN/ACK + ACK)
- Data transfer 
- Connection termination (through **four-way handshake** --> FIN + ACK - FIN + ACK)

Now that we understand how It operates, and what It can offer, let's talk about a few features and options in more details

#### Flow control

Besides what checksum and sequence can achieve, *TCP* includes a flow and congestion control to avoid flooding one node. Having a mechanism for flow control is essential in an environment where machines of diverse network speeds communicate. *TCP* uses a sliding window flow control protocol, where each segment specifies the number of data It is willing to buffer for the connection. The sending host can send only up to that amount of data before It must wait for an acknowledgement and window update from the receiving host.

#### Congestion control

*MSS* is the largest amount of data, specified in bytes, that TCP is willing to receive in a single segment. For best performance, It should be set small enough to avoid *IP fragmentation* so It can pass through a link MTU. This parameter is typically announced on the connection establishment and derived from the MTU size of the data link layer of the networks.

The next aspect is *congestion control*, where *TCP* uses mechanisms to achieve high performance and avoid congestion collapse (when incoming traffic > outgoing bandwidth). It keeps the data flow below a rate that would trigger collapse through four intertwined algorithms: *slow-start, congestion avoidance, fast retransmit and fast recovery*. Without diving into the specifics, these algorithms set a small multiple of the *MSS* allowed on that connection depending on the round-trip time (RTT).

There is a lot more to cover on this part, as there is new algorithms coming in and out every year, and It can also depends on the network visibility (black-box or white-box).

#### Selective acknowledgments

Also called **SACK**, It allows the receiver to acknowledge discontinuous blocks of packets which were received correctly, in addition to the sequence number immediately following the last sequence number received. This option is not mandatory, but has become widespread due to the quality of life improvement on long fat networks.

*TCP* may experience poor performance when multiple packets are lost from one window of data. This forces the sender to either wait a roundtrip time to find out about each lost packet, or to retransmit segments which have been correctly received. With *SACK*, the data receiver can inform the sender about all segments that have arrived successfully, so the sender need to only retransmit the segments that have actually been lost.

#### TCP no delay

Now we will check out a few options that are relevant for Real Time applications, the first one being `TCP_NODELAY`.

*TCP* has had to introduce new heuristics to handle the changes effectively. These heuristics can result in a program becoming unstable. One example of heuristic behavior in TCP is that small buffers are delayed. This allows them to be sent as one network packet. This generally works well, but it can also create latencies.

*TCP_NODELAY* is an option that can be used to turn this behavior off. For it to be used effectively, the application must avoid doing small buffer writes, as TCP will send these buffers as individual packets.

#### TCP cork

Another TCP socket option that works in a similar way is `TCP_CORK`. When enabled, TCP will delay all packets until the application removes the cork, and allows the stored packets to be sent. This allows applications to build a packet in kernel space, which is useful when different libraries are being used to provide layer abstractions. 

### GRPC

Now that we have seen the main protocols (TCP/UDP), we can check out a different type called `gRPC`. It is an open source remote procedure call (RPC) system initially developed at Google in 2015. It uses *HTTP/2* for transport, with protocol buffers, bidirectional streaming and flow control. Most common usage scenarios include connecting services in a microservices style architecture. 

It stands on the session layer, and could be considered a completly different kind from the previous sockets we saw, but  they still create communication channels that enable unrelated processes to exchange data, and It is a very new way for process to communicate, so let's try it !

We will implement a simple client in Go with *BubbleTea TUI*, that will interact with a python server. It will simply provide a list of possible sockets family, then types, then protocols (so we can re-use our previous script). **Why ?** Because I saw those technologies and I thought It would be cool to use them.

The code is available here: https://github.com/maxime-lair/grpc-goclient-pythonserver

The output:

![linux_socket](https://user-images.githubusercontent.com/72258375/150878339-5d889986-843c-4b7e-bc01-9624d990f332.gif)

## Interact with socket

Now that we know how to create and implement sockets, let's check out how we can show and analyze them on Linux.

### Useful commands

Linux includes a nice array of tools to display network activity. One of the most used one is `netstat` but It is on its way to become obsolete, and leave his seat for the `ss` utility. It is supposed to be faster and more human-readable.

#### Netstat

The main example of `netstat` usage would be to display sockets on *LISTEN* state

![image](https://user-images.githubusercontent.com/72258375/151001825-77589782-dc9a-4232-ba90-4868cd91f6df.png)

The command:

![image](https://user-images.githubusercontent.com/72258375/151003431-bc90775a-f529-40d3-8601-6eec1b4411bd.png)

You can notice some well known ports, such as *SSH* (22), *Performance monitor daemon* (44321) but also more obscure one such as *4330*, no idea of its use, and *50051* which was our previous GRPC project server.

There is many more arguments available, but you usually only care for TCP listen connections when handling server. 

For example, to only show *dbus* unix sockets:

![image](https://user-images.githubusercontent.com/72258375/151004063-99a4cb80-667b-4270-a1a4-4345596db84c.png)

#### ss utility

The basic ss command without any options simply lists all the connections regardless of the state they are in. Luckily, It is easy to transition into `ss` from `netstat` as most options operate in much the same fashion.

To check out the *TCP* sockets with their associated *cgroups*

![image](https://user-images.githubusercontent.com/72258375/151011754-3ac45d47-6f9c-4d8d-b8dd-dae8a60c3f39.png)

Or *Unix stream* sockets:

![image](https://user-images.githubusercontent.com/72258375/151012617-1cb9404e-102d-4dde-8261-f10a933cf975.png)

One nice command to check non-localhost sockets:

![image](https://user-images.githubusercontent.com/72258375/151010875-6eee731e-ff57-4f97-867e-8ddc4271822b.png)


#### Others utilities

Since everything is a file in Linux, you can also use `lsof` to check which sockets are in use

For Unix sockets:

![image](https://user-images.githubusercontent.com/72258375/151005799-12d0c7c0-7ecd-448c-998b-5b117bf47bc4.png)

To show the peer :

![image](https://user-images.githubusercontent.com/72258375/151006408-ff50712e-6921-466d-a6ac-58b392ae26a8.png)

You can also use `nc` to start a quick listening socket on any ports, for testing purpose, such as :

![test_nc](https://user-images.githubusercontent.com/72258375/151018397-bb115c29-bfa0-4b8d-8741-bf60ea4fcc29.gif)

### Monitoring

In order to properly monitor our sockets activity, we need to define our search perimeter. 

Sockets are dependent on your network configuration (devices, routing, etc.) and your program ability to process them. It is necessary to have metrics from your hardware, network and process to fully analyze an issue. For example, you could think changing from TCP to UDP could increase your latency, but If you had routing in place depending on TCP or UDP packets in your network, this could skew the results.

This is why we want to focus on what metrics we can retrieve from our sockets. `ss -s` command already gave us a nice idea of the type of information we could be looking for, but where does It take this information from ?

#### /proc

One of the first place we can look into is `/proc`, where we can find networking parameters and statistics.

We can find some nice statistics in `/proc/net`, i.e. *protocols* :

![image](https://user-images.githubusercontent.com/72258375/151013720-b84c1ab4-752e-4149-b349-bec7caaacb6e.png)

Or *sockstat* / *tcp*:

![image](https://user-images.githubusercontent.com/72258375/151014000-1e2bf149-c6ab-4c73-bd19-45ef47bd29c7.png)

Thinking of metrics, we could first start from a top-down perspective, count the number of sockets, by family, type and protocols, then get more specific statistics with popular ones (such as TCP).

For example, taking TCP as a basis, we can check all stats available for TCP:

![image](https://user-images.githubusercontent.com/72258375/151015490-855c961d-4720-485e-81c1-f644552ab958.png)

We can see there is 102 possibles stats for a TCP connection, It could be interesting to check out each of them, as they could be useless or useful depending on your usecase. If you do not have *SACK* activated, you probably won't need it.

![image](https://user-images.githubusercontent.com/72258375/151016141-fd9e8cd4-55f0-4b24-8f54-04a31b064c1f.png)

You can also check out the kernel networking parts in `/proc/sys/net`, where you can see your system networking parameters:

![image](https://user-images.githubusercontent.com/72258375/151016657-fedbe314-3692-40d5-b9a5-687bb717b02c.png)

More information on each directory is available [here](https://www.kernel.org/doc/html/latest/admin-guide/sysctl/net.html?highlight=sockets)

#### /sys

You can also find information in the `/sys` directory

![image](https://user-images.githubusercontent.com/72258375/151020030-869f9b5f-f712-4cf7-b789-658fdf0ec6d7.png)

But most of these informations will depend on your devices, and be most hardware oriented.

![image](https://user-images.githubusercontent.com/72258375/151020410-1a29b9ee-0ccb-4240-aca6-40c8143a7219.png)

## Conclusion

We were able to check out the difference in multiple socket families, types and protocols, with the most popular being TCP/IP, UDP/IP, Unix/DGRAM, Unix/STREAM. We tried to dive into the specifics of TCP and UDP protocols to learn how and why they are different. We created a small project to explore new technologies such as GRPC through a nice golang client and python server, while having a BubbleTea TUI was not important, It was still nice to implement and try it out. We ended up with some commands and metrics we can use to view our system sockets.

Check out some of these credits below and the GRPC repository I linked, as I think I over-complicated some parts and not explained some others, this is one of the longest article I did, mainly due to the client/server side-project.

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
>
> https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_for_real_time/7/html/reference_guide/chap-sockets
>
> https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/s2-proc-dir-net
