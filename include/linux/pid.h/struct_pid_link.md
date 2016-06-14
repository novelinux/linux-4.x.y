struct pid_link
========================================

node
----------------------------------------

path: include/linux/pid.h
```
struct pid_link
{
    struct hlist_node node;
```

node用作散列表元素。

pid
----------------------------------------

```
    struct pid *pid;
};
```

pid指向进程所属的pid结构实例.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/pid.h/struct_pid.md
