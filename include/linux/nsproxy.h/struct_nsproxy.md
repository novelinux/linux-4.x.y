struct nsproxy
========================================

子系统此前的全局属性现在封装到命名空间中，每个进程关联到一个
选定的命名空间。每个可以感知命名空间的内核子系统都必须提供一个
数据结构，将所有通过命名空间形式提供的对象集中起来。
struct nsproxy用于汇集指向特定于子系统的命名空间包装器的指针：

comments
----------------------------------------

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
```

count
----------------------------------------

```
struct nsproxy {
    atomic_t count;
```

uts_ns
----------------------------------------

```
    struct uts_namespace *uts_ns;
```

UTS命名空间包含了运行内核的名称、版本、底层体系结构类型等信息。
UTS是UNIX Timesharing System的简称。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/utsname.h/README.md

ipc_ns
----------------------------------------

```
    struct ipc_namespace *ipc_ns;
```

保存在struct ipc_namespace中的所有与进程间通信(IPC)有关的信息。

mnt_ns
----------------------------------------

```
    struct mnt_namespace *mnt_ns;
```

已经装载的文件系统的视图，在struct mnt_namespace中给出。

pid_ns_for_children
----------------------------------------

```
    struct pid_namespace *pid_ns_for_children;
```

有关进程ID的信息，由struct pid_namespace提供。

net_ns
----------------------------------------

```
    struct net           *net_ns;
};
```

struct net_ns包含所有网络相关的命名空间参数.