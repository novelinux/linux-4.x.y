IPC Namespace
========================================

容器中进程间通信采用的方法包括常见的信号量、消息队列和共享内存。然而与虚拟机不同的是，
容器内部进程间通信对宿主机来说，实际上是具有相同PID namespace中的进程间通信，因此需要
一个唯一的标识符来进行区别。申请IPC资源就申请了这样一个全局唯一的32位ID，所以IPC namespace
中实际上包含了系统IPC标识符以及实现POSIX消息队列的文件系统。在同一个IPC namespace下的进程
彼此可见，而与其他的IPC namespace下的进程则互相不可见。

Data Structure
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/ipc_namespace.h/struct_ipc_namespace.md

init_ipc_ns
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/ipc/msgutil.c/init_ipc_ns.md

Sample
----------------------------------------

IPC namespace在代码上的变化与UTS namespace相似，只是标识位有所变化，需要加上CLONE_NEWIPC参数。
主要改动如下，其他部位不变，程序名称改为ipc.c

```
    int child_pid = clone(child_main, child_stack + STACK_SIZE,
                          CLONE_NEWIPC | CLONE_NEWUTS | SIGCHLD, NULL);
```

我们首先在shell中使用ipcmk -Q命令创建一个message queue。

```
$ ipcmk -Q
Message queue id: 0
```

通过ipcs -q可以查看到已经开启的message queue，序号为0

```
$ ipcs -q

------ Message Queues --------
key        msqid      owner      perms      used-bytes   messages
0x11869f00 0          liminghao  644        0            0
```

然后我们可以编译运行加入了IPC namespace隔离的ipc.c，在新建的子进程中调用的shell中执行ipcs -q查看
message queue。

```
$ sudo ./ipc
[sudo] password for liminghao:
starting ...
in child
# ipcs -q

------ Message Queues --------
key        msqid      owner      perms      used-bytes   messages
```

上面的结果显示中可以发现，已经找不到原先声明的message queue，实现了IPC的隔离。
