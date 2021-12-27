# Process management

In this article, we will talk about process management in any IT operation, we will start by defining what process and managing them means, what commands can help us achieve this, and common pitfalls.

*I will running my lab on a Centos 9 Stream, which came out this very month. Most of this will apply to Linux distribution, I will not cover Unix or Windows command.*

## Definition

__A process__ is any active (i.e. running) instance of a program. A program is a sequence of instructions understanble by the CPU. It can be a ready-to-run program like an executable file.

__Process management__ will handle this process life cycle. From the time a process is born to when It is terminated, It can be runnable, running, sleeping (in memory or on disk) and zombie states.

## Process lifecycle

All processes are descendants of the init process, whose PID is one.

You can check this init process existence with:


## Helpful commands


## Common pitfalls


## Take it a step further




> Credits
> https://www.redhat.com/sysadmin/linux-command-basics-7-commands-process-management
>
>
>
>