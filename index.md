# Road to Devops

## Objective

"Road to Devops" is a project I started recently, as I wanted to learn more about Devops and SRE technologies. Each article is inspired by [this excellent roadmap](https://roadmap.sh/devops), and will try to cover and test my knowledge on each subject before I can dive more into IaC. 

I will try to focus on the inner architecture and useful commands, without diving too much into the details. If you see any inconsistencies or missing items, you are more than welcome to tell me. What I will find interesting next is to use each article as basis for further project ideas.

## Table of contents

*Note: There is/will be no logic in the writing order besides in IaC*

1. [OS Concepts](roadTo/os_concepts)
   - [Process Management](roadTo/os_concepts/process_management)
   - [File systems](roadTo/os_concepts/file_systems)
   - [Memory and storage](roadTo/os_concepts/memory_and_storage)
   - [IO management](roadTo/os_concepts/IO_management)
   - Service management (Systemd)
   - Startup management (Initd)
   - Posix Basics
   - Virtualization
   - Threads and concurrency
   - Sockets
   - Networking concepts
2. [Terminal fu](roadTo/terminal_fu)
   - Bash scripting
   - Vim
   - Compiling Apps (gcc..)
   - System performance
   - Miscellaneous commands (strace, uname..)
   - Text manipulation tools (awk, sed..)
   - Process monitoring (ps, top..)
   - Network (nmap, tcpdump, mtr, dig..)
3. [Managing servers](roadTo/managing_servers)
   - Operating systems
   - Fedora, CentOS and RHEL
   - Ubuntu
   - Unix
   - Windows
4. [Networking, security and protocols](roadTo/networking&security&protocols)
   - Emails protocols
   - Email security
   - DNS
   - OSI Model
   - HTTP/s
   - FTP
   - SSL/TLS
   - SSH
   - Port forwarding
5. [Network solutions](roadTo/network_solutions)
   - Reverse Proxy
   - Caching server
   - Firewall
   - Web servers
   - Load balancer
6. [Programming language](roadTo/programming_language)
   - Python
   - GO
   - Ruby?
7. [Learn infrastructure as code](roadTo/learn_iac)
   - Server mesh
   - CI/CD tool
   - Containers
   - Configuration management
   - Container orchestration
   - Infrastructure provisionning
   - Infrastructure monitoring
   - Application monitoring
   - Logs management
   - Cloud providers
   - Cloud design patterns
   - Let chaos reign ([Chaos monkey](https://www.gremlin.com/chaos-monkey/))

# Projects

## Objective

While writing *roadTo*, I often need to test commands in recent systems, see if everything is still working as It is supposed to, or If there was any upgrades. 

The main project is to build an entire devops infrastructure, with docker, cloud, k8s, ansible, terraform, cloud providers and else. But while working on this, I sometimes have some random ideas about QoL improvements I can have (like a zsh theme that I can replicate among all my systems). This part is used to record those projects and in what state they currently are (mostly WIP).

## Table of contents


1. [Docker initiation](projectBob/index)
- [x] Docker
- [x] httpd/traefik/prometheus/grafana
- [ ] Node_exporter and Cadvisor (WIP)
- [ ] Ansible (WIP)
- [ ] Kubernetes
- [ ] Terraform
- [ ] CI/CD
- [ ] Cloud providers fail-over
- [ ] gRPC
- [ ] Add Email/DHCP/DNS/VPN

2. [Build my own infrastructure](projectBob/pfsense)
3. [QoL improvements](projectBob/)
- [x] [tmux with tmuxinator](projectBob/tmux)
- [ ] [Ozsh theme (WIP)](https://github.com/maxime-lair/zsh_p10k_custom_configuration)
- [x] [Web page for binsh.io](https://github.com/maxime-lair/binsh)