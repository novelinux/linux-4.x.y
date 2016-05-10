命名空间
========================================

传统上，在Linux以及其他衍生的UNIX变体中，许多资源是全局管理的。例如，系统中的所有进程按照惯例是
通过PID标识的，这意味着内核必须管理一个全局的PID列表。而且，所有调用者通过uname系统调用返回的
系统相关信息（包括系统名称和有关内核的一些信息）都是相同的。用户ID的管理方式类似，即各个用户是
通过一个全局唯一的UID号标识。全局ID使得内核可以有选择地允许或拒绝某些特权。虽然UID为0的root用户
基本上允许做任何事，但其他用户ID则会受到限制。例如UID为n的用户，不允许杀死属于用户m的进程（m≠n）。
但这不能防止用户看到彼此，即用户n可以看到另一个用户m也在计算机上活动。只要用户只能操纵他们自己的
进程，这就没什么问题，因为没有理由不允许用户看到其他用户的进程。

但有些情况下，这种效果可能是不想要的。如果提供Web主机的供应商打算向用户提供Linux计算机的全部
访问权限，包括root权限在内。传统上，这需要为每个用户准备一台计算机，代价太高。使用KVM或VMWare
提供的虚拟化环境是一种解决问题的方法，但资源分配做得不是非常好。计算机的各个用户都需要一个
独立的内核，以及一份完全安装好的配套的用户层应用。命名空间提供了一种不同的解决方案，所需资源较少。
在虚拟化的系统中，一台物理计算机可以运行多个内核，可能是并行的多个不同的操作系统。而命名空间则只
使用一个内核在一台物理计算机上运作，前述的所有全局资源都通过命名空间抽象起来。这使得可以将一组进程
放置到容器中，各个容器彼此隔离。隔离可以使容器的成员与其他容器毫无关系。但也可以通过允许容器进行
一定的共享，来降低容器之间的分隔。例如，容器可以设置为使用自身的PID集合，但仍然与其他容器共享部分
文件系统。本质上，命名空间建立了系统的不同视图。此前的每一项全局资源都必须包装到容器数据结构中，
只有资源和包含资源的命名空间构成的二元组仍然是全局唯一的。虽然在给定容器内部资源是自足的，但无法
提供在容器外部具有唯一性的ID。下图给出了此情况的一个概述。

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/sched.h/res/nsproxy.png

考虑系统上有3个不同命名空间的情况。命名空间可以组织为层次，我会在这里讨论这种情况。一个命名空间是
父命名空间，衍生了两个子命名空间。假定容器用于虚拟主机配置中，其中的每个容器必须看起来像是单独的
一台Linux计算机。因此其中每一个都有自身的init进程，PID为0，其他进程的PID以递增次序分配。两个
子命名空间都有PID为0的init进程，以及PID分别为2和3的两个进程。由于相同的PID在系统中出现多次，PID号
不是全局唯一的。虽然子容器不了解系统中的其他容器，但父容器知道子命名空间的存在，也可以看到其中执行
的所有进程。图中子容器的进程映射到父容器中，PID为4到9。尽管系统上有9个进程，但却需要15个PID来表示，
因为一个进程可以关联到多个PID。至于哪个PID是“正确”的，则依赖于具体的上下文。
如果命名空间包含的是比较简单的量，也可以是非层次的，例如下文讨论的UTS命名空间。在这种情况下，
父子命名空间之间没有联系。请注意，Linux系统对简单形式的命名空间的支持已经有很长一段时间了，主要是
chroot系统调用。该方法可以将进程限制到文件系统的某一部分，因而是一种简单的命名空间机制。但真正的
命名空间能够控制的功能远远超过文件系统视图。新的命名空间可以用下面两种方法创建。

* 在用fork或clone系统调用创建新进程时，有特定的选项可以控制是与父进程共享命名空间，
  还是建立新的命名空间。

* unshare系统调用将进程的某些部分从父进程分离，其中也包括命名空间。更多信息请参见手册页unshare(2).
  在进程已经使用上述的两种机制之一从父进程命名空间分离后，从该进程的角度来看，改变全局属性不会传播
  到父进程命名空间，而父进程的修改也不会传播到子进程，至少对于简单的量是这样。而对于文件系统来说，
  情况就比较复杂，其中的共享机制非常强大，带来了大量的可能性.

实际上，Linux内核实现namespace的主要目的就是为了实现轻量级虚拟化（容器）服务。在同一个namespace
下的进程可以感知彼此的变化，而对外界的进程一无所知。这样就可以让容器中的进程产生错觉，仿佛自己
置身于一个独立的系统环境中，以此达到独立和隔离的目的。Linux内核中就提供了这六种namespace隔离的
系统调用，如下表所示:

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/sched.h/nsproxy/res/six.png

APIS
----------------------------------------

namespace的API包括:

* clone()
* setns()
* unshare()
* /proc下的部分文件

为了确定隔离的到底是哪种namespace，在使用这些API时，通常需要指定以下六个常数的一个或多个，
通过|（位或）操作来实现。你可能已经在上面的表格中注意到，这六个参数分别是CLONE_NEWIPC、
CLONE_NEWNS、CLONE_NEWNET、CLONE_NEWPID、CLONE_NEWUSER和CLONE_NEWUTS。

### clone

使用clone()来创建一个独立namespace的进程是最常见做法，它的调用方式如下。

```
int clone(int (*child_func)(void *), void *child_stack, int flags, void *arg);
```

clone()实际上是传统UNIX系统调用fork()的一种更通用的实现方式，它可以通过flags来控制使用多少功能。
一共有二十多种CLONE_*的flag（标志位）参数用来控制clone进程的方方面面（如是否与父进程共享虚拟内存
等等），下面外面逐一讲解clone函数传入的参数。

* 参数child_func传入子进程运行的程序主函数。
* 参数child_stack传入子进程使用的栈空间
* 参数flags表示使用哪些CLONE_*标志位
* 参数args则可用于传入用户参数

### /proc/[pid]/ns

用户就可以在/proc/[pid]/ns文件下看到指向不同namespace号的文件，效果如下所示:

```
root@cancro:/proc/1/ns # ls -l
lrwxrwxrwx root     root              2016-02-18 15:44 mnt -> mnt:[4026531840]
lrwxrwxrwx root     root              2016-02-18 15:44 net -> net:[4026533493]
```

如果两个进程指向的namespace编号相同，就说明他们在同一个namespace下，否则则在不同namespace里面。
/proc/[pid]/ns的另外一个作用是，一旦文件被打开，只要打开的文件描述符（fd）存在，那么就算PID所属
的所有进程都已经结束，创建的namespace就会一直存在。

### setns

在进程都结束的情况下，也可以通过挂载的形式把namespace保留下来，保留namespace的目的自然是为以后
有进程加入做准备。通过setns()系统调用，你的进程从原先的namespace加入我们准备好的新namespace，
使用方法如下。

```
int setns(int fd, int nstype);
```

* 参数fd表示我们要加入的namespace的文件描述符。上文已经提到，它是一个指向/proc/[pid]/ns目录的
文件描述符，可以通过直接打开该目录下的链接或者打开一个挂载了该目录下链接的文件得到。

* 参数nstype让调用者可以去检查fd指向的namespace类型是否符合我们实际的要求。如果填0表示不检查。

为了把我们创建的namespace利用起来，我们需要引入execve()系列函数，这个函数可以执行用户命令，
最常用的就是调用/bin/bash并接受参数，运行起一个shell，用法如下。

```
fd = open(argv[1], O_RDONLY);   /* 获取namespace文件描述符 */
setns(fd, 0);                   /* 加入新的namespace */
execvp(argv[2], &argv[2]);      /* 执行程序 */
```

假设编译后的程序名称为setns。

```
# ./setns ~/uts /bin/bash   # ~/uts 是绑定的/proc/27514/ns/uts
```

至此，你就可以在新的命名空间中执行shell命令了，在下文中会多次使用这种方式来演示隔离的效果。

### unshare

通过unshare()在原先进程上进行namespace隔离, 最后要提的系统调用是unshare()，它跟clone()很像，不同的是，
unshare()运行在原先的进程上，不需要启动一个新进程，使用方法如下。

```
int unshare(int flags);
```

调用unshare()的主要作用就是不启动一个新进程就可以起到隔离的效果，相当于跳出原先的namespace进行
操作。这样，你就可以在原进程进行一些需要隔离的操作。Linux中自带的unshare命令，就是通过unshare()
系统调用实现的.

实现
----------------------------------------

命名空间的实现需要两个部分：每个子系统的命名空间结构，将此前所有的全局组件包装到命名空间中；
将给定进程关联到所属各个命名空间的机制。下图说明了具体情形:

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/sched.h/nsproxy/res/task_with_nsproxy.png

子系统此前的全局属性现在封装到命名空间中，每个进程关联到一个选定的命名空间。每个可以感知命名空间
的内核子系统都必须提供一个数据结构，将所有通过命名空间形式提供的对象集中起来。struct nsproxy用于
汇集指向特定于子系统的命名空间包装器的指针：

path: include/linux/nsproxy.h

```
/*
 * A structure to contain pointers to all per-process
 * namespaces - fs (mount), uts, network, sysvipc, etc.
 *
 * The pid namespace is an exception -- it's accessed using
 * task_active_pid_ns.  The pid namespace here is the
 * namespace that children will use.
 *
 * 'count' is the number of tasks holding a reference.
 * The count for each namespace, then, will be the number
 * of nsproxies pointing to it, not the number of tasks.
 *
 * The nsproxy is shared by tasks which share all namespaces.
 * As soon as a single namespace is cloned or unshared, the
 * nsproxy is copied.
 */
struct nsproxy {
	atomic_t count;
	struct uts_namespace *uts_ns;
	struct ipc_namespace *ipc_ns;
	struct mnt_namespace *mnt_ns;
	struct pid_namespace *pid_ns_for_children;
	struct net 	     *net_ns;
};
```

当前内核的以下范围可以感知到命名空间:
* UTS命名空间包含了运行内核的名称、版本、底层体系结构类型等信息。UTS是UNIX Timesharing System
  的简称。
* 保存在struct ipc_namespace中的所有与进程间通信（IPC）有关的信息。
* 已经装载的文件系统的视图，在struct mnt_namespace中给出。
* 有关进程ID的信息，由struct pid_namespace提供。
* struct user_namespace保存的用于限制每个用户资源使用的信息。
* struct net_ns包含所有网络相关的命名空间参数。

为使网络相关的内核代码能够完全感知命名空间，还有许多工作需要完成。当我讨论相应的子系统时，
会介绍各个命名空间容器的内容。在本章中，我们主要讲解UTS和用户命名空间。由于在创建新进程时可
使用fork建立一个新的命名空间，因此必须提供控制该行为的适当的标志。

每个命名空间都有一个对应的标志：
path: include/uapi/linux/sched.h
```
#define CLONE_NEWNS	0x00020000	/* New mount namespace group */
...
/* 0x02000000 was previously the unused CLONE_STOPPED (Start in stopped state)
   and is now available for re-use. */
#define CLONE_NEWUTS		0x04000000	/* New utsname namespace */
#define CLONE_NEWIPC		0x08000000	/* New ipc namespace */
#define CLONE_NEWUSER		0x10000000	/* New user namespace */
#define CLONE_NEWPID		0x20000000	/* New pid namespace */
#define CLONE_NEWNET		0x40000000	/* New network namespace */
```

每个进程都关联到自身的命名空间视图：

path: include/linux/sched.h

```
struct task_struct {
    ...
    /* 命名空间 */
    struct nsproxy *nsproxy;
    ...
};
```

因为使用了指针，多个进程可以共享一组子命名空间。这样，修改给定的命名空间，对所有属于该
命名空间的进程都是可见的。请注意，对命名空间的支持必须在编译时启用，而且必须逐一指定
需要支持的命名空间。但对命名空间的一般性支持总是会编译到内核中。这使得内核不管有无命名空间，
都不必使用不同的代码。除非指定不同的选项，否则每个进程都会关联到一个默认命名空间，这样可
感知命名空间的代码总是可以使用。但如果内核编译时没有指定对具体命名空间的支持，默认命名空间的
作用则类似于不启用命名空间，所有的属性都相当于全局的。init_nsproxy定义了初始的全局命名空间，
其中维护了指向各子系统初始的命名空间对象的指针：

path: kernel/nsproxy.c

```
struct nsproxy init_nsproxy = {
	.count			= ATOMIC_INIT(1),
	.uts_ns			= &init_uts_ns,
#if defined(CONFIG_POSIX_MQUEUE) || defined(CONFIG_SYSVIPC)
	.ipc_ns			= &init_ipc_ns,
#endif
	.mnt_ns			= NULL,
	.pid_ns_for_children	= &init_pid_ns,
#ifdef CONFIG_NET
	.net_ns			= &init_net,
#endif
};
```

### UTS namespace

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/sched.h/nsproxy/UTS_namespace.md

### IPC namespace

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/sched.h/nsproxy/IPC_namespace.md

### MNT namespace

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/sched.h/nsproxy/MNT_namespace.md

### PID namespace

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/sched.h/nsproxy/PID_namespace.md

### USER namespace

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/sched.h/nsproxy/USER_namespace.md

### NET namespace

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/sched.h/nsproxy/NET_namespace.md