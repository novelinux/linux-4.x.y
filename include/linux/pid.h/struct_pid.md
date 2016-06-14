struct pid
========================================

struct pid是内核对PID的内部表示.

count
----------------------------------------

path: include/linux/pid.h
```
struct pid
{
    atomic_t count;
```

引用计数器count.

level
----------------------------------------

```
    unsigned int level;
```

一个进程可能在多个命名空间中可见，而其在各个命名空间中的局部ID各不相同。
level表示可以看到该进程的命名空间的数目, 即: 包含该进程的命名空间在命名空间层次结构中的深度.

tasks
----------------------------------------

```
    /* lists of tasks that use this pid */
    struct hlist_head tasks[PIDTYPE_MAX];
```

tasks是一个数组，每个数组项都是一个散列表头，对应于一个ID类型。这样做是必要的，因为一个ID
可能用于几个进程。所有共享同一给定ID的task_struct实例，都通过该列表连接起来。PIDTYPE_MAX
表示ID类型的数目:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/pid.h/enum_pid_type.md

rcu
----------------------------------------

```
    struct rcu_head rcu;
```

numbers
----------------------------------------

```
    struct upid numbers[1];
};
```

numbers是一个upid实例的数组，每个数组项都对应于一个命名空间。注意该数组形式上只有一个数组项，
如果一个进程只包含在全局命名空间中，那么确实如此。由于该数组位于结构的末尾，因此只要分配更多
的内存空间，即可向数组添加附加的项。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/pid.h/struct_upid.md
