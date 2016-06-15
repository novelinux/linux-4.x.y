struct fdtable
========================================

max_fds
----------------------------------------

path: include/linux/fdtable.h
```
struct fdtable {
    unsigned int max_fds;
```

max_fds指定了进程当前可以处理的文件对象和文件描述符的最大数目。这里没有固有的上限，因为
这两个值都可以在必要时增加（只要没有超出由Rlimit指定的值，但这与文件结构无关）。尽管内核
使用的文件对象和文件描述符的数目总是相同的，但必须定义不同的最大数目。这归因于管理相关
数据结构的方法。

fd
----------------------------------------

```
    struct file __rcu **fd;      /* current fd array */
```

fd是一个指针数组，每个数组项指向一个file结构的实例，管理一个打开文件的所有信息。用户空间进程
的文件描述符充当数组索引。该数组当前的长度由max_fds定义。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_file.md

close_on_exec
----------------------------------------

```
    unsigned long *close_on_exec;
```

close_on_exec也是一个指向位域的指针，该位域保存了所有在exec系统调用时将要关闭的文件描述符的信息。

open_fds
----------------------------------------

```
    unsigned long *open_fds;
```

open_fds是一个指向位域的指针，该位域管理着当前所有打开文件的描述符。每个可能的文件描述符都
对应着一个比特位。如果该比特位置位，则对应的文件描述符处于使用中；否则该描述符未使用。
当前比特位置的最大数目由max_fdset指定。

rcu
----------------------------------------

```
    struct rcu_head rcu;
};
```