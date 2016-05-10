struct thread_info
========================================

通常栈和thread_info一同保存在一个联合中，thread_info保存了线程所需的所有特定于处理器的底层信息。

path: arch/arm/include/asm/thread_info.h
```
/*
 * low level task data that entry.S needs immediate access to.
 * __switch_to() assumes cpu_context follows immediately after cpu_domain.
 */
struct thread_info {
    unsigned long       flags;        /* low level flags */
    int                 preempt_count;    /* 0 => preemptable, <0 => bug */
    mm_segment_t        addr_limit;    /* address limit */
    struct task_struct  *task;        /* main task structure */
    struct exec_domain  *exec_domain;    /* execution domain */
    __u32               cpu;        /* cpu */
    __u32               cpu_domain;    /* cpu domain */
    struct cpu_context_save    cpu_context;    /* cpu context */
    __u32               syscall;    /* syscall number */
    __u8                used_cp[16];    /* thread used copro */
    unsigned long       tp_value;
    struct crunch_state crunchstate;
    union fp_state      fpstate __attribute__((aligned(8)));
    union vfp_state     vfpstate;
#ifdef CONFIG_ARM_THUMBEE
    unsigned long        thumbee_state;    /* ThumbEE Handler Base register */
#endif
    struct restart_block    restart_block;
};
```

* task是指向进程task_struct实例的指针。

* exec_domain用于实现执行区间（execution domain），后者用于在一类计算机上实现多种的
  ABI（Application Bi-nary Interface，应用程序二进制接口）。例如，在AMD64系统的64bit
  模式下运行32bit应用程序。

* flags可以保存各种特定于进程的标志，我们对其中两个特别感兴趣，如下所示:
1.如果进程有待决信号则置位TIF_SIGPENDING。
2.TIF_NEED_RESCHED表示该进程应该或想要调度器选择另一个进程替换本进程执行。

* cpu说明了进程正在其上执行的CPU数目（在多处理器系统上很重要，在单处理器系统上非常容易判断）。

* preempt_count实现内核抢占所需的一个计数器。

* addr_limit指定了进程可以使用的虚拟地址的上限。如前所述，该限制适用于普通进程，但内核线程
  可以访问整个虚拟地址空间，包括只有内核能访问的部分。这并不意味着限制进程可以分配的内存数量。

* restart_block用于实现信号机制

#### struct cpu_context_save

cpu_context_save这个数据结构是内核线程上下文，当有线程切换发生时会用到:

path: arch/arm/include/asm/thread_info.h
```
struct cpu_context_save {
    __u32    r4;
    __u32    r5;
    __u32    r6;
    __u32    r7;
    __u32    r8;
    __u32    r9;
    __u32    sl;
    __u32    fp;
    __u32    sp;
    __u32    pc;
    __u32    extra[2];        /* Xscale 'acc' register, etc */
};
```