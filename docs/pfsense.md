# PFSense installation

To change keyboard layout in PFSense (will reset at next reboot)
`kbdcontrol -l /usr/share/syscons/keymaps/[YOUR LOCALE LANGUAGE].iso.kbd`

## WAN/LAN configuration

WAN is the wide area network, and is often considered the "outside" network. Internet is a *type* of WAN, but It could be your entire company network. It usually means "this is a network which has no finite geographical limit, systems could be anywhere in the world".

We want this WAN to be able to access the Internet in our case, and our main objective is to ping a popular DNS IP (like cloudfare 1.1.1.1 or google 8.8.8.8) and receives a response back. This means checking for ICMP filtering, and having a public IP.

For this, we will be running this inside an hypervisor called ESXi, and with several public IPs provided by my service provider (I bought a whole block, registered to RIPE).

First, let's create our network bridge. We want our private network to be able to reach public network, but we don't want random public network to poll our private network. That means they need to communicate through a firewall, that's PFSense.

First, our public network is defined with this IP block, this is what I was assigned to:
`
Public IP:  141.95.187.105

Gateway:    141.95.187.110

Netmask:    255.255.255.248 (/29)
`

We now have two choices:
- Create our PFSense, assign it this IP and create two VLANs that will act as WAN and LAN.
- Create *vNIC* together *vSwitch* in our hypervisor ESXi that will act as our LAN network.

Question is: do we create our LAN network at the hypervisor level, or VM level ? Both could work (see *router on a stick*)
But It's recommended to create them at the hypervisor level, as It makes it way easier to create new VMs in this LAN network, and in PFSense, you can restart one network adapter without bothering the other.

So let's create our *vSwitch* and *vNic*, check out [this post to understand why *Nic* are needed](https://docs.microsoft.com/en-us/windows-hardware/drivers/network/nic-switches)

We create our vSwitch by indicating which uplink we want (physical network adapter on ESXi), I have two availables:

![image](https://user-images.githubusercontent.com/72258375/147661859-53af1ae4-6eb3-42fe-a7c9-38348c4a1b6d.png)


One is used for the ESXi management (*vmnic0*), the other is free to use, so we create our *vSwitch* named _vSwitchLab_:

![image](https://user-images.githubusercontent.com/72258375/147661940-9ed21d75-b6a1-4197-8201-d3a6d909dd74.png)

![image](https://user-images.githubusercontent.com/72258375/147661994-8d5c0fa9-dce1-418e-ae38-68e2de19c57c.png)

Then we create a port groups, that will be standing behind this vSwitch, we call it _Lab Network_

![image](https://user-images.githubusercontent.com/72258375/147662061-d0db6857-5895-4046-88c9-89a6a9ddec93.png)

and we create our *vNic* to stand on the other side:

![image](https://user-images.githubusercontent.com/72258375/147662181-4d56ec89-9082-425f-a586-9d99e5fa2ea1.png)

You might notice It created an IP automatically : *192.168.1.100* - It is a [private network](https://www.arin.net/reference/research/statistics/address_filters/)

And now, we are ready to create our PFSense VM, with two network adapters :

- One for our WAN
- One for our LAN

![image](https://user-images.githubusercontent.com/72258375/147662504-1990c282-fcae-4164-9c81-bb43b427cdf8.png)

One detail to note, we need to assign a MAC address on our outside-facing network card, as It will be facing the Internet. This MAC address will be linked with our public IP.

On this first network adapter, we use "Advanced..." and assign its MAC address. One detail is If we create VLAN from this network adapter, they will all share the same MAC address.

Now we can start our PFSense, and after installation, we are greeted by this menu:

![image](https://user-images.githubusercontent.com/72258375/147663049-467c177f-c1e6-42d9-8e63-a1bfdc133937.png)

We want to first assign interfaces, and then set our interface(s) IP address.

When assigning interfaces, we want:
- em0 (VM Network) to be our WAN
- em1 (Lab Network) to be our LAN

Do not create any VLAN or downgrade the console to http, It is not needed.

Then we set our IPs, they are static on both sides, since we do not have a DHCP server assigning them:
- em0 <-> WAN <-> Public IP: 141.95.187.105/29 with gateway 141.95.187.110
- em1 <-> LAN <-> Private IP: 10.0.0.1/24 ([could have used up to /8](https://en.wikipedia.org/wiki/Private_network)) with no gateway (as we are our own gateway)

I could have used any IP in available private subnets : 10.0.0.0/8, 172.16.0.0/12 or 192.168.0.0/16

Let's try to ping an outside of network DNS:

![image](https://user-images.githubusercontent.com/72258375/147663682-59107466-1e1d-4677-a25c-de4dc7a71040.png)

Our firewall is able to ping outside network, all is left is to create a VM with a GUI in the LAN network to reach PFSense web interface, and have it able to reach outside network by going through our PFSense firewall.

# Installing a lab in our LAN

## Network connectivity

### Reasoning

_Note:_ I will be using a CentOS 9 Stream, which came out this month. 

When creating the VM in ESXi, create a network adapter assigned to "Lab Network"

![image](https://user-images.githubusercontent.com/72258375/147664021-1c129243-ad32-4a2f-aeb2-e3a500aeb778.png)

After installing our OS, our system is unable to connect to its network. This is normal as he doesn't have a DHCP server to give him his IP, we have to manually set it up.

For this, I will be using [NetworkManager CLI](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-configuring_ip_networking_with_nmcli), also named *nmcli*, as It's better suited for scripting and I want to test it out. Others setups will probably prefer using configuration files, and that would have been my first choice had I not decided to try out this CLI.

My end goal would be to include the next commands in my Ansible playbook when I want to create more VMs.

### Set up static IP through nmcli

First, we check which devices we will use:

![image](https://user-images.githubusercontent.com/72258375/147653668-df93e522-1b04-426c-88d9-46ba7043ffa2.png)

*ens32* will be our dedicated device. Here _nmcli dev_ stands for _nmcli device status_ - It's a nice shortcut.

It's possible to create this device through _nmcli_ but we already did that when creating the VM.

Our network, as defined in PFSense, will look like this:
`
Network:    10.0.0.0/24
Gateway:    10.0.0.1
Broadcast:  10.0.0.255
Mask(/24):  255.255.255.0
`

Since this is our first system we set up in this network, let's just increment and use the first available IP: *10.0.0.2*
For others installations, we will try to have a DHCP server to assign this automatically.

`nmcli connection modify ens32 ipv4.addresses "10.0.0.2/24" ipv4.gateway "10.0.0.1 ipv4.method manual"`

Our device is now set with his static IP, and indicating the gateway creates the route. Be careful as the default connection is usually with DHCP activated (_ipv4.method_ set to manual instead of auto)

If you need to check all availables variables, check out your configuration in _/etc/NetworkManager/system-connections/[CON-NAME].nmconnection_

![image](https://user-images.githubusercontent.com/72258375/147657723-2db5567d-506f-4e7a-98c6-4ffee165bd38.png)

All green, all good ! Let's try to ping our gateway:

![image](https://user-images.githubusercontent.com/72258375/147660146-97aceaac-1987-4702-9719-1777c5a1d0c9.png)

Naturally, It works, as we are in the same LAN as defined on ESXi and our VM configuration. But can we reach outside network ?

![image](https://user-images.githubusercontent.com/72258375/147660237-f9bac85e-4a28-458e-a9fc-523d748f42d3.png)

We can, great ! If that didn't work, we could have looked into the ICMP traffic, if PFSense was rejecting them by default.

Now we can connect to PFSense GUI and start enhancing our setup from our CentOS in LAN

![image](https://user-images.githubusercontent.com/72258375/147660324-97cd4a87-2a9d-45ac-af3a-1a398039fee7.png)

By default, this GUI is only available on the LAN side, as to not expose it to outside network ([how easy would It be to scan IPs for PFSense first install](https://www.shodan.io/search?query=pfsense)).

Default user is *admin* / *pfsense*

And we are good to go !

![image](https://user-images.githubusercontent.com/72258375/147664313-394962d8-bf62-471a-acba-9490dcf5ca42.png)

All is left is to add some firewall rules, create new VMs in this network, and we are all set !

We end up with this infrastructure:

![image](https://user-images.githubusercontent.com/72258375/147668332-6befe267-9e69-45ef-808b-11ae498df370.png)

Lanlab(s) will be used to host kubernetes nodes, and esxi-lab is here for quick services testing.

*Credits*

> https://docs.ovh.com/au/en/dedicated/pfSense-bridging/#requirements
> https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-configuring_ip_networking_with_nmcli








