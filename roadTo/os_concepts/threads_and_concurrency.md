# Threads and concurrency

In this article we will talk about threads and writing programs with concurrency in mind. I will try to dive in the definition of threads, how they are used today, and the common pitfalls we can encounter.

*Note:* I'm using a CentOS 9 Stream which came out last month, so a few things might differ from your distro.

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

I will be using **Go** language, because why not. It's possible to have finer tuning by using C/C++ `kthreads.h` library, in order to create kernel threads on the fly for example. But they are extremely hard to use because most native data structures (e.g. Hashes or Dictionaries) will break. This [post](https://stackoverflow.com/questions/15983872/difference-between-user-level-and-kernel-supported-threads) explains it very well.

It is much easier to use user-threads (also called *Green threads*) as starter, as they are managed by your language, and chance are, they know what they are doing better than you (e.g. such as seeing partially-copied structure, transforming blocking calls into async). The best of both worlds is : use one OS thread per CPU core (since that's your hardware limit anyway), and many green threads that can attach to any OS threads available. Languages like *Go* and *Erlang* provide this feature.

### Actors-based pattern

In this model, each actor possesses a mailbox and can be addressed. They do not share a shared state, and when they need to communicate, they send a message and continue without blocking. Each actor will go through this mailbox and schedules each message received for execution. They also include a private state (occupied, etc.), and can make local decisions and create more actors.

![image](https://user-images.githubusercontent.com/72258375/148783212-fb69d9f0-3208-4a3a-a5bf-415b53ce3b9a.png)

It is used by [**Akka**](https://doc.akka.io/docs/akka/current/typed/guide/actors-intro.html) for example

Why use them in threads if they are not going to have a shared state then ? Because It will be able to execute asynchronously and distributed by design. It alleviates the code from having to deal with explicit locking and thread management. There is a few implementations possible, namely *thread-driven actors* and *event-driven actors*.

Let's create a simple program, which will receive a list of string, and return each bcrypt hash. Each hash calculation has to be done by an actor.





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
