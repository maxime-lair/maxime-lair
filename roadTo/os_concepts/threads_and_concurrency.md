# Threads and concurrency

In this article we will talk about threads and writing programs with concurrency in mind. I will try to dive in the definition of threads, how they are used today, and the common pitfalls we can encounter.

*Note:* I'm using a CentOS 9 Stream which came out last month, so a few things might differ from your distro.

The implementation will be done in **Go** language, I could have done that in any other language, but I wanted to try this one.

## Definition

A thread of execution is the smallest sequence of programmed instructions that can be managed independently by a scheduler. In most cases, a thread is a component of a process. The multiple threads of a given process may be executed concurrently, sharing resources such as memory while different processes do not share these resources. In particular, the threads of a process share its executable code and the values of its dynamically allocated variables and (non-thread-local) global variables at any given time.

Popularity of threading has increased around 2003, as the growth of the CPU frequency was replaced with the growth of number of cores, in turn requiring concurrency to utilize multiple cores. Even today, finding programs which include multi-core support is rare.

A process is a unit of resources, while a thread is a unit of scheduling and execution. There is typically two types of threads: kernel and user. Kernel thread is the base unit of kernel scheduling, each process possess at least one, and owns a stack, registers and thread-local storage. User threads are the opposite, as they are managed and scheduled in the userspace, the kernel is unaware of them, this makes them extremely efficient at context switching.

Using a process is relatively expensive, as they own resources allocated by the operating system such as memory, file and devices handles or sockets. They are isolated and do not share address spaces or file resources unless you use an IPC. This is why threads are often preferred in case you need to often communicate in parallel (e.g. a GUI and its backend), they however increase the chance of bug since one misbehaving thread can disrupt the processing of all the other threads sharing the same address space in the application.

![image](https://user-images.githubusercontent.com/72258375/148702658-336a4ed9-9e4a-4554-a1b5-c70849759ea4.png)

## Implement threads

Now that we know what threads are, how do we actually implement them ? There is a few models that exist for Kernel/User threads, namely:
- One to One model: One user-thread is matched against the same kernel-thread
  - Better for synchronization and blocking issues
  - Bad for performance (thread limits is quickly reached, and kernel is required for each operations)
- Many to One model: Multiple user-threads are matched against one kernel-thread
  - Better for portability, and less dependency on kernel thread limits
  - Bad If one user-thread blocks a kernel-thread
- Many to Many model: have bound/unbound threads
  - Best implementation 
  - Requires coordination between user/kernel thread managers (namely pool)

In order to understand them better, let's study a few multithreading design patterns

### Design patterns

We will first focus on a usecase where we receive a task, onto which we will apply a truly independent computation, and return the result. In the next part, we will try to understand how we can share this data, and perform *thread-safe* concurrency with lock and communication.

### Actors-based pattern

Used by Netty and Akka

Each thread is able to perform a task and communicate by message

#### Boss/workers pattern

Used by NodeJS and Nginx

Boss acts as the thread manager, workers perform tasks

Also called **Event-based pattern**

## Concurrency

IPC / Locking (semaphore) / Mutex / Thread safety

## Pitfalls

Deadlocks / Race conditions / Starvation / Livelock

## Conclusion


> Credits
>
> https://www.oreilly.com/library/view/the-art-of/9780596802424/ch04.html
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
> 
> 
> 
> 
