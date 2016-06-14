PID
========================================

UNIX进程总是会分配一个号码用于在其命名空间中唯一地标识它们。该号码被称作进程ID号，简称PID。
用fork或clone产生的每个进程都由内核自动地分配了一个新的唯一的PID值。

但每个进程除了PID这个特征值之外，还有其他的ID。有下列几种可能的类型:

* 处于某个线程组（在一个进程中，以标志CLONE_THREAD来调用clone建立的该进程的不同的执行上下文）
中的所有进程都有统一的线程组ID（TGID）。如果进程没有使用线程，则其PID和TGID相同。线程组中的
主进程被称作组长（group leader）。通过clone创建的所有线程的task_struct的group_leader成员，
会指向组长的task_struct实例.

* 另外，独立进程可以合并成进程组（使用setpgrp系统调用）。进程组成员的task_struct的pgrp属性值
都是相同的，即进程组组长的PID。进程组简化了向组的所有成员发送信号的操作，这对于各种系统程序设计
应用是有用的。请注意，用管道连接的进程包含在同一个进程组中。

* 几个进程组可以合并成一个会话。会话中的所有进程都有同样的会话ID，保存在task_struct的session
成员中。SID可以使用setsid系统调用设置。

Data Structure
----------------------------------------

### Global ID

全局PID和TGID直接保存在task_struct中，分别是task_struct的pid和tgid成员：

path: include/linux/sched.h
```
    pid_t pid;
    pid_t tgid;
```

### Local ID

除了上述两个字段之外，内核还需要找一个办法来管理所有命名空间内部的局部量，以及其他ID(如TID和SID).
这需要几个相互连接的数据结构，以及许多辅助函数.

由于所有共享同一ID的task_struct实例都按进程存储在一个散列表中，因此需要在struct task_struct
中增加一个散列表元素:

```
    /* PID/PID hash table linkage. */
    struct pid_link pids[PIDTYPE_MAX];
```

辅助数据结构pid_link可以将task_struct连接到表头在struct pid中的散列表上：

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/pid.h/struct_pid_link.md

此外，内核需要提供辅助函数，以实现通过ID及其类型查找进程的task_struct的功能，以及将ID的内核表示
形式和用户空间可见的数值进行转换的功能。

上述各结构组织如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/pid.h/res/pid.jpg

### pid_hash

为在给定的命名空间中查找对应于指定PID数值的pid结构实例，使用了一个散列表:

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/pid.c/pid_hash.md

APIS
----------------------------------------

### alloc_pid

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/pid.c/alloc_pid.md

### attach_pid

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/pid.c/attach_pid.md

### task -> pid

#### task_pid

给出task_struct、ID类型、命名空间，取得命名空间局部的数字ID。
辅助函数task_pid、task_tgid、task_pgrp和task_session分别用于取得不同类型的ID。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/sched.h/task_pid.md

获取TGID的做法类似，因为TGID不过是线程组组长的PID而已。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/sched.h/task_pgrp.md

#### pid_vnr vs pid_nr

##### pid_vnr

pid_vnr返回该ID所属的命名空间所看到的局部PID.

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/pid.c/pid_vnr.md

##### pid_nr

pid_nr则获取从init进程看到的全局PID。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/pid.h/pid_nr.md

### pid --> task_struct

给出局部数字ID和对应的命名空间，查找此二元组描述的task_struct.
内核如何将数字PID和命名空间转换为pid实例。同样需要下面两个步骤:

#### find_pid_ns

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/pid.c/find_pid_ns.md

#### pid_task

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/pid.c/pid_task.md

#### find_task_by_pid_ns

这两个步骤可以通过辅助函数find_task_by_pid_type_ns完成：

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/pid.c/find_task_by_pid_ns.md
