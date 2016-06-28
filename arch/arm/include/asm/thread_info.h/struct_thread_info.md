struct thread_info
========================================

通常栈和thread_info一同保存在一个联合中，thread_info保存了线程所需的所有特定于处理器的底层信息。

flags
----------------------------------------

可以保存各种特定于进程的标志，我们对其中两个特别感兴趣，如下所示:
1.如果进程有待决信号则置位TIF_SIGPENDING。
2.TIF_NEED_RESCHED表示该进程应该或想要调度器选择另一个进程替换本进程执行。

path: arch/arm/include/asm/thread_info.h
```
/*
 * low level task data that entry.S needs immediate access to.
 * __switch_to() assumes cpu_context follows immediately after cpu_domain.
 */
struct thread_info {
    unsigned long       flags;        /* low level flags */
```

preempt_count
----------------------------------------

实现内核抢占所需的一个计数器。

```
    int                 preempt_count;    /* 0 => preemptable, <0 => bug */
```

addr_limit
----------------------------------------

指定了进程可以使用的虚拟地址的上限。如前所述，该限制适用于普通进程，但内核线程
可以访问整个虚拟地址空间，包括只有内核能访问的部分。这并不意味着限制进程可以分配的内存数量。

```
    mm_segment_t        addr_limit;    /* address limit */
```

task
----------------------------------------

是指向进程task_struct实例的指针。

```
    struct task_struct  *task;        /* main task structure */
```

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/sched.h/struct_task_struct.md

exec_domain
----------------------------------------

用于实现执行区间（execution domain），后者用于在一类计算机上实现多种的
ABI（Application Bi-nary Interface，应用程序二进制接口）。例如，在AMD64系统的64bit
模式下运行32bit应用程序。

```
    struct exec_domain  *exec_domain;    /* execution domain */
```

cpu
----------------------------------------

说明了进程正在其上执行的CPU数目（在多处理器系统上很重要，在单处理器系统上非常容易判断）。

```
    __u32               cpu;        /* cpu */
```

cpu_domain
----------------------------------------

```
    __u32               cpu_domain;    /* cpu domain */
```

cpu_context
----------------------------------------

```
    struct cpu_context_save    cpu_context;    /* cpu context */
```

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/include/asm/thread_info.h/struct_cpu_context_save.md

syscall
----------------------------------------

```
    __u32               syscall;    /* syscall number */
    __u8                used_cp[16];    /* thread used copro */
    unsigned long        tp_value[2];    /* TLS registers */
#ifdef CONFIG_CRUNCH
    struct crunch_state    crunchstate;
#endif
    union fp_state        fpstate __attribute__((aligned(8)));
    union vfp_state        vfpstate;
#ifdef CONFIG_ARM_THUMBEE
    unsigned long        thumbee_state;    /* ThumbEE Handler Base register */
#endif
};
```
