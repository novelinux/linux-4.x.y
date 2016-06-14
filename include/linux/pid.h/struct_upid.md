struct upid
========================================

struct upid则表示特定的命名空间中可见的信息。

nr
----------------------------------------

path: include/linux/pid.h
```
/*
 * struct upid is used to get the id of the struct pid, as it is
 * seen in particular namespace. Later the struct pid is found with
 * find_pid_ns() using the int nr and struct pid_namespace *ns.
 */

struct upid {
    /* Try to keep pid_chain in the same cacheline as nr for find_vpid */
    int nr;
```

nr表示ID的数值;

ns
----------------------------------------

```
    struct pid_namespace *ns;
```

ns是指向该ID所属的命名空间的指针;

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/pid_namespace.h/struct_pid_namespace.md

pid_chain
----------------------------------------

```
    struct hlist_node pid_chain;
};
```

pid_chain用内核的标准方法实现了散列溢出链表。