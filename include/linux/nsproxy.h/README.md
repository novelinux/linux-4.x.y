Namespace
========================================

传统上，在Linux以及其他衍生的UNIX变体中，许多资源是全局管理的。
例如，系统中的所有进程按照惯例是通过PID标识的，这意味着内核必须
管理一个全局的PID列表。而且，所有调用者通过uname系统调用返回的
系统相关信息（包括系统名称和有关内核的一些信息）都是相同的。
用户ID的管理方式类似，即各个用户是通过一个全局唯一的UID号标识。
全局ID使得内核可以有选择地允许或拒绝某些特权。虽然UID为0的root用户
基本上允许做任何事，但其他用户ID则会受到限制。例如UID为n的用户，
不允许杀死属于用户m的进程（m≠n）。但这不能防止用户看到彼此，即用户n
可以看到另一个用户m也在计算机上活动。只要用户只能操纵他们自己的
进程，这就没什么问题，因为没有理由不允许用户看到其他用户的进程。

但有些情况下，这种效果可能是不想要的。如果提供Web主机的供应商打算
向用户提供Linux计算机的全部访问权限，包括root权限在内。传统上，
这需要为每个用户准备一台计算机，代价太高。使用KVM或VMWare提供的虚拟化
环境是一种解决问题的方法，但资源分配做得不是非常好。计算机的各个用户
都需要一个独立的内核，以及一份完全安装好的配套的用户层应用。
命名空间提供了一种不同的解决方案，所需资源较少。在虚拟化的系统中，一台
物理计算机可以运行多个内核，可能是并行的多个不同的操作系统。而命名空间
则只使用一个内核在一台物理计算机上运作，前述的所有全局资源都通过命名空间
抽象起来。这使得可以将一组进程放置到容器中，各个容器彼此隔离。隔离可以
使容器的成员与其他容器毫无关系。但也可以通过允许容器进行一定的共享，
来降低容器之间的分隔。例如，容器可以设置为使用自身的PID集合，但仍然与其他
容器共享部分文件系统。本质上，命名空间建立了系统的不同视图。此前的每一项
全局资源都必须包装到容器数据结构中，只有资源和包含资源的命名空间构成的
二元组仍然是全局唯一的。虽然在给定容器内部资源是自足的，但无法
提供在容器外部具有唯一性的ID。下图给出了此情况的一个概述。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/nsproxy.h/res/nsproxy.jpg

考虑系统上有3个不同命名空间的情况。命名空间可以组织为层次，我会在这里讨论这种情况。
一个命名空间是父命名空间，衍生了两个子命名空间。假定容器用于虚拟主机配置中，
其中的每个容器必须看起来像是单独的一台Linux计算机。因此其中每一个都有自身的init进程，
PID为0，其他进程的PID以递增次序分配。两个子命名空间都有PID为0的init进程，以及PID分别为
2和3的两个进程。由于相同的PID在系统中出现多次，PID号不是全局唯一的。虽然子容器不了解
系统中的其他容器，但父容器知道子命名空间的存在，也可以看到其中执行的所有进程。图中子
容器的进程映射到父容器中，PID为4到9。尽管系统上有9个进程，但却需要15个PID来表示，
因为一个进程可以关联到多个PID。至于哪个PID是“正确”的，则依赖于具体的上下文。
如果命名空间包含的是比较简单的量，也可以是非层次的，例如下文讨论的UTS命名空间。
在这种情况下，父子命名空间之间没有联系。请注意，Linux系统对简单形式的命名空间的
支持已经有很长一段时间了，主要是chroot系统调用。该方法可以将进程限制到文件系统的
某一部分，因而是一种简单的命名空间机制。但真正的命名空间能够控制的功能远远超过文件
系统视图。新的命名空间可以用下面两种方法创建。

* 在用fork或clone系统调用创建新进程时，有特定的选项可以控制是与父进程共享命名空间，
  还是建立新的命名空间。

* unshare系统调用将进程的某些部分从父进程分离，其中也包括命名空间。
  在进程已经使用上述的两种机制之一从父进程命名空间分离后，从该进程
  的角度来看，改变全局属性不会传播到父进程命名空间，而父进程的修改
  也不会传播到子进程，至少对于简单的量是这样。而对于文件系统来说，
  情况就比较复杂，其中的共享机制非常强大，带来了大量的可能性.

实际上，Linux内核实现namespace的主要目的就是为了实现轻量级虚拟化（容器）服务。
在同一个namespace下的进程可以感知彼此的变化，而对外界的进程一无所知。
这样就可以让容器中的进程产生错觉，仿佛自己置身于一个独立的系统环境中，
以此达到独立和隔离的目的。Linux内核中就提供了这六种namespace隔离的
系统调用，如下表所示:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/nsproxy.h/res/six.png

Data Structure
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/nsproxy.h/struct_nsproxy.md

init_nsproxy
----------------------------------------

init_nsproxy定义了初始的全局命名空间，其中维护了指向各子系统初始的命名空间对象的指针：

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/nsproxy.c/init_nsproxy.md

Flags
----------------------------------------

由于在创建新进程时可使用fork建立一个新的命名空间，因此必须提供控制该行为的适当的标志。
每个命名空间都有一个对应的标志：

path: include/uapi/linux/sched.h
```
#define CLONE_NEWNS    0x00020000    /* New mount namespace group */
...
/* 0x02000000 was previously the unused CLONE_STOPPED (Start in stopped state)
   and is now available for re-use. */
#define CLONE_NEWUTS        0x04000000    /* New utsname namespace */
#define CLONE_NEWIPC        0x08000000    /* New ipc namespace */
#define CLONE_NEWUSER        0x10000000    /* New user namespace */
#define CLONE_NEWPID        0x20000000    /* New pid namespace */
#define CLONE_NEWNET        0x40000000    /* New network namespace */
```

APIS
----------------------------------------

namespace的API包括:

### clone

https://github.com/novelinux/linux-4.x.y/blob/master/kernel/fork.c/clone.md

### setns

https://github.com/novelinux/linux-4.x.y/blob/master/kernel/nsproxy.c/setns.md

### unshare

https://github.com/novelinux/linux-4.x.y/blob/master/kernel/fork.c/unshare.md

### /proc

为了确定隔离的到底是哪种namespace，在使用这些API时，通常需要指定以下六个常数的一个或多个，
通过|（位或）操作来实现。你可能已经在上面的表格中注意到，这六个参数分别是CLONE_NEWIPC、
CLONE_NEWNS、CLONE_NEWNET、CLONE_NEWPID、CLONE_NEWUSER和CLONE_NEWUTS.

用户就可以在/proc/[pid]/ns文件下看到指向不同namespace号的文件，效果如下所示:

```
root@cancro:/proc/1/ns # ls -l
lrwxrwxrwx root     root              2016-02-18 15:44 mnt -> mnt:[4026531840]
lrwxrwxrwx root     root              2016-02-18 15:44 net -> net:[4026533493]
```

如果两个进程指向的namespace编号相同，就说明他们在同一个namespace下，否则则在不同namespace里面。
/proc/[pid]/ns的另外一个作用是，一旦文件被打开，只要打开的文件描述符（fd）存在，那么就算PID所属
的所有进程都已经结束，创建的namespace就会一直存在。
