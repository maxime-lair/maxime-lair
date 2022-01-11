# Sockets

Here we will study the different sockets available and how they function. We will try to implement some, and check the latency between local socket and multi-host ones.

## Definition

Operating systems include the BSD interprocess communication facility known as *sockets*. They are communication channels that enable unrelated processes to exchange data *locally and across networks**. 

A *socket* uniquely identifies the endpoint of a communication link between two application ports. A socket is typically representated through five informations:
- The domain
- The type
- The protocol
- The hostname
- The port

This [quintuple](https://en.wiktionary.org/wiki/quintuple) is used to correctly identify a socket on a host. This host will add this socket to its local table by associating it with a socket descriptor (a binary integer).

**TODO Explain socket domain**

While a socket is mostly used over a network to allow two hosts to communicate between each other, communication between local processes (e.g. IPC) also makes use of socket. Sockets are classified according to communication properties. Each socket has an associated type, which describes the semantics of communications using that socket. Each socket type incurs different properties such as reliability, ordering and session control. The most common ones are :
- Stream socket
- Datagram socket
- Raw socket
- Unix domain socket

Then, the socket has to support a protocol to allow data exchange through a standard set of rules such as UDP or TCP over IP.

**TODO Tree like image of domain -> types -> protocols**

We will go through each socket type, and implement a simple client/server in each. Different protocols will be used and shortly explained, as this is the subject of another article (i.e. *networking concepts*).

## Socket creation

Create - Bind - Listen - Accept - Read - Close
Create - Bind -  Connect - Write - Close

## Socket types

### Stream socket

### Datagram socket

### Raw socket

### Unix domain socket

## Socket protocol

### UDP

### TCP

### GRPC


## Conclusion

> Credits
>
> https://www.ibm.com/docs/en/zos/2.2.0?topic=functions-socket-create-socket
>
> https://www.digitalocean.com/community/tutorials/understanding-sockets
> 
> https://ops.tips/blog/how-linux-creates-sockets/
> 
> https://www.ibm.com/docs/en/zos/2.2.0?topic=concepts-tcpip
> 
> https://www.tutorialspoint.com/unix_sockets/what_is_socket.htm
> 
> https://www.ibm.com/docs/pl/aix/7.1?topic=concepts-sockets
> 
> https://ipfs.io/ipfs/QmfYeDhGH9bZzihBUDEQbCbTc5k5FZKURMUoUvfmc27BwL/socket/services.html
