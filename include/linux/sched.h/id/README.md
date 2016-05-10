进程id号
========================================

UNIX进程总是会分配一个号码用于在其命名空间中唯一地标识它们。该号码被称作进程ID号，简称PID。
用fork或clone产生的每个进程都由内核自动地分配了一个新的唯一的PID值。

进程ID
----------------------------------------

但每个进程除了PID这个特征值之外，还有其他的ID。有下列几种可能的类型:

* 处于某个线程组（在一个进程中，以标志CLONE_THREAD来调用clone建立的该进程的不同的执行上下文）中的
所有进程都有统一的线程组ID（TGID）。如果进程没有使用线程，则其PID和TGID相同。线程组中的主进程被
称作组长（group leader）。通过clone创建的所有线程的task_struct的group_leader成员，会指向组长的
task_struct实例.

* 另外，独立进程可以合并成进程组（使用setpgrp系统调用）。进程组成员的task_struct的pgrp属性值
都是相同的，即进程组组长的PID。进程组简化了向组的所有成员发送信号的操作，这对于各种系统程序设计
应用是有用的。请注意，用管道连接的进程包含在同一个进程组中。

* 几个进程组可以合并成一个会话。会话中的所有进程都有同样的会话ID，保存在task_struct的session成员中。
SID可以使用setsid系统调用设置。

命名空间增加了PID管理的复杂性。回想一下，PID命名空间按层次组织。在建立一个新的命名空间时，
该命名空间中的所有PID对父命名空间都是可见的，但子命名空间无法看到父命名空间的PID。但这意味着
某些进程具有多个PID，凡可以看到该进程的命名空间，都会为其分配一个PID。这必须反映在数据结构中。
我们必须区分局部ID和全局ID。

* 全局ID是在内核本身和初始命名空间中的唯一ID号，在系统启动期间开始的init进程即属于初始命名空间。
  对每个ID类型，都有一个给定的全局ID，保证在整个系统中是唯一的。全局PID和TGID直接保存在task_struct
  中，分别是task_struct的pid和tgid成员：

```
    pid_t pid;
    pid_t tgid;
```

这两项都是pid_t类型，该类型定义为__kernel_pid_t，后者由各个体系结构分别定义。通常定义为int，
即可以同时使用232个不同的ID。会话和进程组ID不是直接包含在task_struct本身中，但保存在用于信号
处理的结构中。task_struct->signal->__ses-sion表示全局SID，而全局PGID则保存在
task_struct->signal->__pgrp。辅助函数set_task_session和set_task_pgrp可用于修改这些值。

* 局部ID属于某个特定的命名空间，不具备全局有效性。对每个ID类型，它们在所属的命名空间内部有效，
但类型相同、值也相同的ID可能出现在不同的命名空间中。

管理PID
----------------------------------------

除了这两个字段之外，内核还需要找一个办法来管理所有命名空间内部的局部量，以及其他ID（如TID和SID）。
这需要几个相互连接的数据结构，以及许多辅助函数，在必要的情况下，我会明确地说明ID类型
（例如，TGID，即线程组ID）。一个小型的子系统称之为PID分配器（pid allocator）用于加速新ID的分配。
此外，内核需要提供辅助函数，以实现通过ID及其类型查找进程的task_struct的功能，以及将ID的内核表示
形式和用户空间可见的数值进行转换的功能。

在介绍表示ID本身所需的数据结构之前，我需要讨论PID命名空间的表示方式。我们所需查看的代码如下所示：

path: include/linux/pid_namespace.h
```
struct pid_namespace {
    struct kref kref;
    struct pidmap pidmap[PIDMAP_ENTRIES];
    struct rcu_head rcu;
    int last_pid;
    unsigned int nr_hashed;
    struct task_struct *child_reaper;
    struct kmem_cache *pid_cachep;
    unsigned int level;
    struct pid_namespace *parent;
#ifdef CONFIG_PROC_FS
    struct vfsmount *proc_mnt;
    struct dentry *proc_self;
    struct dentry *proc_thread_self;
#endif
#ifdef CONFIG_BSD_PROCESS_ACCT
    struct bsd_acct_struct *bacct;
#endif
    struct user_namespace *user_ns;
    struct work_struct proc_work;
    kgid_t pid_gid;
    int hide_pid;
    int reboot;    /* group exit code if this pidns was rebooted */
    struct ns_common ns;
};
```

实际上PID分配器也需要依靠该结构的某些部分来连续生成唯一ID.

* 每个PID命名空间都具有一个进程，其发挥的作用相当于全局的init进程。init的一个目的是对孤儿进程调用
wait4，命名空间局部的init变体也必须完成该工作。child_reaper保存了指向该进程的task_struct的指针。

* parent是指向父命名空间的指针，层次表示当前命名空间在命名空间层次结构中的深度。初始命名空间的
level为0，该命名空间的子空间level为1，下一层的子空间level为2，依次递推。level的计算比较重要，
因为level较高的命名空间中的ID，对level较低的命名空间来说是可见的。从给定的level设置，内核即可推断
进程会关联到多少个ID。

PID的管理围绕两个数据结构展开: struct pid是内核对PID的内部表示，而struct upid则表示特定的命名空间
中可见的信息。两个结构的定义如下：

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
    struct pid_namespace *ns;
    struct hlist_node pid_chain;
};

struct pid
{
    atomic_t count;
    unsigned int level;
    /* lists of tasks that use this pid */
    struct hlist_head tasks[PIDTYPE_MAX];
    struct rcu_head rcu;
    struct upid numbers[1];
};
```

### struct upid

* nr表示ID的数值;
* ns是指向该ID所属的命名空间的指针;
* pid_chain用内核的标准方法实现了散列溢出链表。

### struct pid:

* 引用计数器count。
* tasks是一个数组，每个数组项都是一个散列表头，对应于一个ID类型。这样做是必要的，因为一个ID
  可能用于几个进程。所有共享同一给定ID的task_struct实例，都通过该列表连接起来。PIDTYPE_MAX
  表示ID类型的数目:

path: include/linux/pid.h
```
enum pid_type
{
    PIDTYPE_PID,
    PIDTYPE_PGID,
    PIDTYPE_SID,
    PIDTYPE_MAX
};
```

**注意**: 枚举类型中定义的ID类型不包括线程组ID！这是因为线程组ID无非是线程组组长的PID而已，
          因此再单独定义一项是不必要的。

一个进程可能在多个命名空间中可见，而其在各个命名空间中的局部ID各不相同。

* level表示可以看到该进程的命名空间的数目(即包含该进程的命名空间在命名空间层次结构中的深度);
* numbers是一个upid实例的数组，每个数组项都对应于一个命名空间。注意该数组形式上只有一个数组项，
  如果一个进程只包含在全局命名空间中，那么确实如此。由于该数组位于结构的末尾，因此只要分配更多
  的内存空间，即可向数组添加附加的项。

由于所有共享同一ID的task_struct实例都按进程存储在一个散列表中，因此需要在
struct task_struct中增加一个散列表元素:

```
    /* PID/PID hash table linkage. */
    struct pid_link pids[PIDTYPE_MAX];
```

辅助数据结构pid_link可以将task_struct连接到表头在struct pid中的散列表上：

path: include/linux/pid.h
```
struct pid_link
{
    struct hlist_node node;
    struct pid *pid;
};
```

上述各结构组织如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/sched.h/id/res/id_struct.jpg

pid指向进程所属的pid结构实例，node用作散列表元素。为在给定的命名空间中查找对应于指定PID数值的pid
结构实例，使用了一个散列表:

path: kernel/pid.c
```
static struct hlist_head *pid_hash;
```

pid_hash用作一个hlist_head数组。数组的元素数目取决于计算机的内存配置，大约在24=16和212=4096之间。
pidhash_init用于计算恰当的容量并分配所需的内存。

相关函数
----------------------------------------

### 1.alloc_pid

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/kernel/pid.c/alloc_pid.md

### 2.attach_pid

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/kernel/pid.c/attach_pid.md

### 3.task_struct <--> ID

内核提供了若干辅助函数，用于操作和扫描上面描述的数据结构。本质上内核必须完成下面两个不同的任务:

#### task_struct --> ID

给出task_struct、ID类型、命名空间，取得命名空间局部的数字ID。

1.获得与task_struct关联的pid实例。辅助函数task_pid、task_tgid、task_pgrp和task_session分别用于
取得不同类型的ID。获取PID的实现很简单：

path: include/linux/sched.h
```
static inline struct pid *task_pid(struct task_struct *task)
{
    return task->pids[PIDTYPE_PID].pid;
}
```

获取TGID的做法类似，因为TGID不过是线程组组长的PID而已。只要将上述实现替换为
task->group_leader->pids[PIDTYPE_PID].pid即可。
找出进程组ID则需要使用PIDTYPE_PGID作为数组索引，但该ID仍然需要从线程组组长的task_struct实例获取：

path: include/linux/sched.h
```
/*
 * Without tasklist or rcu lock it is not safe to dereference
 * the result of task_pgrp/task_session even if task == current,
 * we can race with another thread doing sys_setsid/sys_setpgid.
 */
static inline struct pid *task_pgrp(struct task_struct *task)
{
    return task->group_leader->pids[PIDTYPE_PGID].pid;
}
```

2.在获得pid实例之后，从struct pid的numbers数组中的uid信息，即可获得数字ID：

path: kernel/pid.c
```
pid_t pid_nr_ns(struct pid *pid, struct pid_namespace *ns)
{
    struct upid *upid;
    pid_t nr = 0;

    // 因为父命名空间可以看到子命名空间中的PID，反过来却不行，内核必须确保当前命名空间的level
    // 小于或等于产生局部PID的命名空间的level。
    if (pid && ns->level <= pid->level) {
        upid = &pid->numbers[ns->level];
        if (upid->ns == ns)
            nr = upid->nr;
    }
    return nr;
}

pid_t pid_vnr(struct pid *pid)
{
    return pid_nr_ns(pid, current->nsproxy->pid_ns);
}
```

同样重要的是要注意到，内核只需要关注产生全局PID。因为全局命名空间中所有其他ID类型都会映射到PID，
因此不必生成诸如全局TGID或SID。

除了在使用的pid_nr_ns之外，内核还可以使用下列辅助函数：

* pid_vnr返回该ID所属的命名空间所看到的局部PID；
* pid_nr则获取从init进程看到的全局PID。

这两个函数都依赖于pid_nr_ns，并自动选择适当的level：0用于获取全局PID，而pid->level则用于
获取局部PID。内核提供了几个辅助函数，合并了前述步骤：

path: kernel/pid.c
```
pid_t task_pid_nr_ns(struct task_struct *tsk, struct pid_namespace *ns)
pid_t task_tgid_nr_ns(struct task_struct *tsk, struct pid_namespace *ns)
pid_t task_pgrp_nr_ns(struct task_struct *tsk, struct pid_namespace *ns)
pid_t task_session_nr_ns(struct task_struct *tsk, struct pid_namespace *ns)
```

#### ID --> task_struct

给出局部数字ID和对应的命名空间，查找此二元组描述的task_struct.
内核如何将数字PID和命名空间转换为pid实例。同样需要下面两个步骤:

1.给出进程的局部数字PID和关联的命名空间(这是PID的用户空间表示),为确定pid实例(这是PID的内核表示)，
  内核必须采用标准的散列方案。首先，根据PID和命名空间指针计算在pid_hash数组中的索引，然后遍历
  散列表直至找到所要的元素。这是通过辅助函数find_pid_ns处理的：

path: kernel/pid.c
```
struct pid *find_pid_ns(int nr, struct pid_namespace *ns)
{
    struct hlist_node *elem;
    struct upid *pnr;

    // struct upid的实例保存在散列表中，由于这些实例直接包含在struct pid中，内核可以使用
    // container_of机制
    hlist_for_each_entry_rcu(pnr, elem,
            &pid_hash[pid_hashfn(nr, ns)], pid_chain)
        if (pnr->nr == nr && pnr->ns == ns)
            return container_of(pnr, struct pid,
                    numbers[ns->level]);

    return NULL;
}
```

2.pid_task函数取出pid->tasks[type]散列表中的第一个task_struct实例。这两个步骤可以通过辅助函数
  find_task_by_pid_type_ns完成：

path: kernel/pid.c
```
struct task_struct *pid_task(struct pid *pid, enum pid_type type)
{
    struct task_struct *result = NULL;
    if (pid) {
        struct hlist_node *first;
        first = rcu_dereference_check(hlist_first_rcu(&pid->tasks[type]),
                          lockdep_tasklist_lock_is_held());
        if (first)
            result = hlist_entry(first, struct task_struct, pids[(type)].node);
    }
    return result;
}

/*
 * Must be called under rcu_read_lock().
 */
struct task_struct *find_task_by_pid_ns(pid_t nr, struct pid_namespace *ns)
{
    rcu_lockdep_assert(rcu_read_lock_held(),
               "find_task_by_pid_ns() needs rcu_read_lock()"
               " protection");
    return pid_task(find_pid_ns(nr, ns), PIDTYPE_PID);
}
```

一些简单一点的辅助函数基于最一般性的find_task_by_pid_type_ns：

* find_task_by_pid_ns(pid_t nr, struct pid_namespace* ns)
  根据给出的数字PID和进程的命名空间来查找task_struct实例。

* find_task_by_vpid(pid_t vnr)
  通过局部数字PID查找进程。

* find_task_by_pid(pid_t nr)
  通过全局数字PID查找进程。

内核源代码中许多地方都需要find_task_by_pid，因为很多特定于进程的操作(例如，使用kill发送一个信号)
都通过PID标识目标进程。
