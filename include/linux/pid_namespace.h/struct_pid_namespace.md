struct pid_namespace
========================================

每个PID命名空间都具有一个进程，其发挥的作用相当于全局的init进程。init的一个目的是对孤儿进程调用
wait4，命名空间局部的init变体也必须完成该工作。实际上PID分配器也需要依靠该结构的某些部分来连续
生成唯一ID.

命名空间增加了PID管理的复杂性。PID命名空间按层次组织。在建立一个新的命名空间时，该命名空间中的
所有PID对父命名空间都是可见的，但子命名空间无法看到父命名空间的PID。但这意味着某些进程具有多个
PID，凡可以看到该进程的命名空间，都会为其分配一个PID。这必须反映在数据结构中。

kref
----------------------------------------

path: include/linux/pid_namespace.h
```
struct pid_namespace {
    struct kref kref;
```

pidmap
----------------------------------------

```
    struct pidmap pidmap[PIDMAP_ENTRIES];
```

rcu
----------------------------------------

```
    struct rcu_head rcu;
```

last_pid
----------------------------------------

```
    int last_pid;
```

nr_hashed
----------------------------------------

```
    unsigned int nr_hashed;
```

child_reaper
----------------------------------------

```
    struct task_struct *child_reaper;
```

child_reaper保存了指向该进程的task_struct的指针。

pid_cachep
----------------------------------------

```
    struct kmem_cache *pid_cachep;
```

level
----------------------------------------

```
    unsigned int level;
```

层次表示当前命名空间在命名空间层次结构中的深度。初始命名空间的level为0，
该命名空间的子空间level为1，下一层的子空间level为2，依次递推。level的计算比较重要，
因为level较高的命名空间中的ID，对level较低的命名空间来说是可见的。从给定的level设置，
内核即可推断进程会关联到多少个ID。

parent
----------------------------------------

```
    struct pid_namespace *parent;
```

parent是指向父命名空间的指针.

proc_*
----------------------------------------

```
#ifdef CONFIG_PROC_FS
    struct vfsmount *proc_mnt;
    struct dentry *proc_self;
    struct dentry *proc_thread_self;
#endif
```

bacct
----------------------------------------

```
#ifdef CONFIG_BSD_PROCESS_ACCT
    struct fs_pin *bacct;
#endif
```

user_ns
----------------------------------------

```
    struct user_namespace *user_ns;
```

proc_work
----------------------------------------

```
    struct work_struct proc_work;
```

pid_gid
----------------------------------------

```
    kgid_t pid_gid;
```

hide_pid
----------------------------------------

```
    int hide_pid;
```

reboot
----------------------------------------

```
    int reboot;    /* group exit code if this pidns was rebooted */
```

ns
----------------------------------------

```
    struct ns_common ns;
};
```