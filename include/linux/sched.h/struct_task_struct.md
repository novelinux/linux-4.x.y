struct task_struct
========================================

Linux内核涉及进程和程序的所有算法都围绕一个名为task_struct的
数据结构建立，该结构定义在include/sched.h中。这是系统中主要的
一个结构。task_struct包含很多成员，将进程与各个内核子系统联系起来.

该结构的内容可以分解为各个部分，每个部分表示进程的一个特定方面。

* 状态和执行信息，如待决信号、使用的二进制格式（和其他系统二进制格式的任何仿真信息）、
  进程ID号（pid）、到父进程及其他有关进程的指针、优先级和程序执行有关的时间信息(例如CPU时间);

* 有关已经分配的虚拟内存的信息;

* 进程身份凭据，如用户ID、组ID以及权限等。可使用系统调用查询（或修改）这些数据;

* 使用的文件包含程序代码的二进制文件，以及进程所处理的所有文件的文件系统信息，这些都必须保存下来;

* 线程信息记录该进程特定于CPU的运行时间数据（该结构的其余字段与所使用的硬件无关）;

* 在与其他应用程序协作时所需的进程间通信有关的信息;

* 该进程所用的信号处理程序，用于响应到来的信号;

state
----------------------------------------

path: include/linux/sched.h
```
struct task_struct {
    volatile long state;    /* -1 unrunnable, 0 runnable, >0 stopped */
```

指定了进程的当前状态，可使用下列值:

* TASK_RUNNING

意味着进程处于可运行状态。这并不意味着已经实际分配了CPU。
进程可能会一直等到调度器选中它。该状态确保进程可以立即运行，
而无需等待外部事件。

* TASK_INTERRUPTIBLE

是针对等待某事件或其他资源的睡眠进程设置的。在内核发送信号给
该进程表明事件已经发生时，进程状态变为TASK_RUNNING，它只要
调度器选中该进程即可恢复执行。

* TASK_UNINTERRUPTIBLE

用于因内核指示而停用的睡眠进程。它们不能由外部信号唤醒，只能由
内核亲自唤醒。

* TASK_STOPPED

表示进程特意停止运行，例如，由调试器暂停。

* TASK_TRACED

本来不是进程状态，用于从停止的进程中，将当前被调试的那些
(使用ptrace机制)与常规的进程区分开来。

stack
----------------------------------------

```
    void *stack;
    atomic_t usage;
    unsigned int flags;    /* per process flags, defined below */
    unsigned int ptrace;

#ifdef CONFIG_SMP
    struct llist_node wake_entry;
    int on_cpu;
    unsigned int wakee_flips;
    unsigned long wakee_flip_decay_ts;
    struct task_struct *last_wakee;

    int wake_cpu;
#endif
    int on_rq;

    int prio, static_prio, normal_prio;
    unsigned int rt_priority;
    const struct sched_class *sched_class;
    struct sched_entity se;
    struct sched_rt_entity rt;
#ifdef CONFIG_CGROUP_SCHED
    struct task_group *sched_task_group;
#endif
    struct sched_dl_entity dl;

#ifdef CONFIG_PREEMPT_NOTIFIERS
    /* list of struct preempt_notifier: */
    struct hlist_head preempt_notifiers;
#endif

#ifdef CONFIG_BLK_DEV_IO_TRACE
    unsigned int btrace_seq;
#endif

    unsigned int policy;
    int nr_cpus_allowed;
    cpumask_t cpus_allowed;

#ifdef CONFIG_PREEMPT_RCU
    int rcu_read_lock_nesting;
    union rcu_special rcu_read_unlock_special;
    struct list_head rcu_node_entry;
    struct rcu_node *rcu_blocked_node;
#endif /* #ifdef CONFIG_PREEMPT_RCU */
#ifdef CONFIG_TASKS_RCU
    unsigned long rcu_tasks_nvcsw;
    bool rcu_tasks_holdout;
    struct list_head rcu_tasks_holdout_list;
    int rcu_tasks_idle_cpu;
#endif /* #ifdef CONFIG_TASKS_RCU */

#ifdef CONFIG_SCHED_INFO
    struct sched_info sched_info;
#endif

    struct list_head tasks;
#ifdef CONFIG_SMP
    struct plist_node pushable_tasks;
    struct rb_node pushable_dl_tasks;
#endif

    struct mm_struct *mm, *active_mm;
    /* per-thread vma caching */
    u32 vmacache_seqnum;
    struct vm_area_struct *vmacache[VMACACHE_SIZE];
#if defined(SPLIT_RSS_COUNTING)
    struct task_rss_stat    rss_stat;
#endif
/* task state */
    int exit_state;
    int exit_code, exit_signal;
    int pdeath_signal;  /*  The signal sent when the parent dies  */
    unsigned long jobctl;    /* JOBCTL_*, siglock protected */

    /* Used for emulating ABI behavior of previous Linux versions */
    unsigned int personality;

    /* scheduler bits, serialized by scheduler locks */
    unsigned sched_reset_on_fork:1;
    unsigned sched_contributes_to_load:1;
    unsigned sched_migrated:1;
    unsigned :0; /* force alignment to the next boundary */

    /* unserialized, strictly 'current' */
    unsigned in_execve:1; /* bit to tell LSMs we're in execve */
    unsigned in_iowait:1;
#ifdef CONFIG_MEMCG
    unsigned memcg_may_oom:1;
#ifndef CONFIG_SLOB
    unsigned memcg_kmem_skip_account:1;
#endif
#endif
#ifdef CONFIG_COMPAT_BRK
    unsigned brk_randomized:1;
#endif

    unsigned long atomic_flags; /* Flags needing atomic access. */

    struct restart_block restart_block;
```

pid, tgid
----------------------------------------

```
    pid_t pid;
    pid_t tgid;
```

全局ID是在内核本身和初始命名空间中的唯一ID号，在系统启动期间开始的init进程即属于初始命名空间。
对每个ID类型，都有一个给定的全局ID，保证在整个系统中是唯一的。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/pid.h/README.md

这两项都是pid_t类型，该类型定义为__kernel_pid_t，后者由各个体系结构分别定义。通常定义为int，
即可以同时使用232个不同的ID。会话和进程组ID不是直接包含在task_struct本身中，但保存在用于信号
处理的结构中。task_struct->signal->__ses-sion表示全局SID，而全局PGID则保存在
task_struct->signal->__pgrp。辅助函数set_task_session和set_task_pgrp可用于修改这些值。

stack_canary
----------------------------------------

```
#ifdef CONFIG_CC_STACKPROTECTOR
    /* Canary value for the -fstack-protector gcc feature */
    unsigned long stack_canary;
#endif
    /*
     * pointers to (original) parent process, youngest child, younger sibling,
     * older sibling, respectively.  (p->father can be replaced with
     * p->real_parent->pid)
     */
    struct task_struct __rcu *real_parent; /* real parent process */
    struct task_struct __rcu *parent; /* recipient of SIGCHLD, wait4() reports */
```

children, sibling
----------------------------------------

```
    /*
     * children/sibling forms the list of my natural children
     */
    struct list_head children;    /* list of my children */
    struct list_head sibling;    /* linkage in my parent's children list */
```

除了源于ID连接的关系之外,内核还负责管理建立在UNIX进程创建模型之上“家族关系”.
相关讨论一般使用下列术语:

* 如果进程A分支形成进程B，进程A称之为父进程而进程B则是子进程。如果进程B再次分支建立另一个进程C，
  进程A和进程C之间有时称之为祖孙关系。
* 如果进程A分支若干次形成几个子进程B1，B2，...，Bn，各个Bi进程之间的关系称之为兄弟关系。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/sched.h/res/task_relation.jpg

* children: 是链表表头，该链表中保存有进程的所有子进程。

* sibling: 用于将兄弟进程彼此连接起来。新的子进程置于sibling链表的起始位置，这意味着可以
  重建进程分支的时间顺序。

group_leader
----------------------------------------

```
    struct task_struct *group_leader;    /* threadgroup leader */

    /*
     * ptraced is the list of tasks this task is using ptrace on.
     * This includes both natural children and PTRACE_ATTACH targets.
     * p->ptrace_entry is p's link on the p->parent->ptraced list.
     */
    struct list_head ptraced;
    struct list_head ptrace_entry;
```

pids
----------------------------------------

```
    /* PID/PID hash table linkage. */
    struct pid_link pids[PIDTYPE_MAX];
```

局部ID属于某个特定的命名空间，不具备全局有效性。对每个ID类型，它们在所属的命名空间内部有效，
但类型相同、值也相同的ID可能出现在不同的命名空间中。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/pid.h/README.md

thread_group
----------------------------------------

```
    struct list_head thread_group;
    struct list_head thread_node;

    struct completion *vfork_done;        /* for vfork() */
    int __user *set_child_tid;        /* CLONE_CHILD_SETTID */
    int __user *clear_child_tid;        /* CLONE_CHILD_CLEARTID */

    cputime_t utime, stime, utimescaled, stimescaled;
    cputime_t gtime;
    struct prev_cputime prev_cputime;
#ifdef CONFIG_VIRT_CPU_ACCOUNTING_GEN
    seqcount_t vtime_seqcount;
    unsigned long long vtime_snap;
    enum {
        /* Task is sleeping or running in a CPU with VTIME inactive */
        VTIME_INACTIVE = 0,
        /* Task runs in userspace in a CPU with VTIME active */
        VTIME_USER,
        /* Task runs in kernelspace in a CPU with VTIME active */
        VTIME_SYS,
    } vtime_snap_whence;
#endif
    unsigned long nvcsw, nivcsw; /* context switch counts */
    u64 start_time;        /* monotonic time in nsec */
    u64 real_start_time;    /* boot based time in nsec */
/* mm fault and swap info: this can arguably be seen as either mm-specific or thread-specific */
    unsigned long min_flt, maj_flt;

    struct task_cputime cputime_expires;
    struct list_head cpu_timers[3];

/* process credentials */
    const struct cred __rcu *real_cred; /* objective and real subjective task
                     * credentials (COW) */
    const struct cred __rcu *cred;    /* effective (overridable) subjective task
                     * credentials (COW) */
    char comm[TASK_COMM_LEN]; /* executable name excluding path
                     - access with [gs]et_task_comm (which lock
                       it with task_lock())
                     - initialized normally by setup_new_exec */
```

nameidata
----------------------------------------

```
/* file system info */
    struct nameidata *nameidata;
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/struct_nameidata.md

CONFIG_SYSVIPC
----------------------------------------

```
#ifdef CONFIG_SYSVIPC
/* ipc stuff */
    struct sysv_sem sysvsem;
    struct sysv_shm sysvshm;
#endif
```

CONFIG_DETECT_HUNG_TASK
----------------------------------------

```
#ifdef CONFIG_DETECT_HUNG_TASK
/* hung task detection */
    unsigned long last_switch_count;
#endif
```

fs
----------------------------------------

```
/* filesystem information */
    struct fs_struct *fs;
```

进程的文件系统相关数据保存在fs中.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs_struct.h/struct_fs_struct.md

files
----------------------------------------

```
/* open file information */
    struct files_struct *files;
```

files包含当前进程的各个文件描述符.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fdtable.h/struct_files_struct.md

nsproxy
----------------------------------------

```
/* namespaces */
    struct nsproxy *nsproxy;
```

每个进程都关联到自身的命名空间视图:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/nsproxy.h/README.md

因为使用了指针，多个进程可以共享一组子命名空间。这样，修改给定的命名空间，对所有属于该命名空间
的进程都是可见的。请注意，对命名空间的支持必须在编译时启用，而且必须逐一指定需要支持的命名
空间。但对命名空间的一般性支持总是会编译到内核中。这使得内核不管有无命名空间，都不必使用不同的
代码。除非指定不同的选项，否则每个进程都会关联到一个默认命名空间，这样可感知命名空间的代码总是
可以使用。但如果内核编译时没有指定对具体命名空间的支持，默认命名空间的作用则类似于不启用命名空间，
所有的属性都相当于全局的。

命名空间的实现需要两个部分：每个子系统的命名空间结构，将此前所有的全局组件包装到命名空间中；
将给定进程关联到所属各个命名空间的机制。下图说明了具体情形:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/nsproxy.h/res/task_nsproxy.jpg

signal
----------------------------------------

```
/* signal handlers */
    struct signal_struct *signal;
    struct sighand_struct *sighand;

    sigset_t blocked, real_blocked;
    sigset_t saved_sigmask;    /* restored if set_restore_sigmask() was used */
    struct sigpending pending;

    unsigned long sas_ss_sp;
    size_t sas_ss_size;

    struct callback_head *task_works;

    struct audit_context *audit_context;
#ifdef CONFIG_AUDITSYSCALL
    kuid_t loginuid;
    unsigned int sessionid;
#endif
    struct seccomp seccomp;

/* Thread group tracking */
       u32 parent_exec_id;
       u32 self_exec_id;
/* Protection of (de-)allocation: mm, files, fs, tty, keyrings, mems_allowed,
 * mempolicy */
    spinlock_t alloc_lock;

    /* Protection of the PI data structures: */
    raw_spinlock_t pi_lock;

    struct wake_q_node wake_q;

#ifdef CONFIG_RT_MUTEXES
    /* PI waiters blocked on a rt_mutex held by this task */
    struct rb_root pi_waiters;
    struct rb_node *pi_waiters_leftmost;
    /* Deadlock detection and priority inheritance handling */
    struct rt_mutex_waiter *pi_blocked_on;
#endif

#ifdef CONFIG_DEBUG_MUTEXES
    /* mutex deadlock detection */
    struct mutex_waiter *blocked_on;
#endif
#ifdef CONFIG_TRACE_IRQFLAGS
    unsigned int irq_events;
    unsigned long hardirq_enable_ip;
    unsigned long hardirq_disable_ip;
    unsigned int hardirq_enable_event;
    unsigned int hardirq_disable_event;
    int hardirqs_enabled;
    int hardirq_context;
    unsigned long softirq_disable_ip;
    unsigned long softirq_enable_ip;
    unsigned int softirq_disable_event;
    unsigned int softirq_enable_event;
    int softirqs_enabled;
    int softirq_context;
#endif
#ifdef CONFIG_LOCKDEP
# define MAX_LOCK_DEPTH 48UL
    u64 curr_chain_key;
    int lockdep_depth;
    unsigned int lockdep_recursion;
    struct held_lock held_locks[MAX_LOCK_DEPTH];
    gfp_t lockdep_reclaim_gfp;
#endif
#ifdef CONFIG_UBSAN
    unsigned int in_ubsan;
#endif

/* journalling filesystem info */
    void *journal_info;

/* stacked block device info */
    struct bio_list *bio_list;

#ifdef CONFIG_BLOCK
/* stack plugging */
    struct blk_plug *plug;
#endif

/* VM state */
    struct reclaim_state *reclaim_state;

    struct backing_dev_info *backing_dev_info;

    struct io_context *io_context;

    unsigned long ptrace_message;
    siginfo_t *last_siginfo; /* For ptrace use.  */
    struct task_io_accounting ioac;
#if defined(CONFIG_TASK_XACCT)
    u64 acct_rss_mem1;    /* accumulated rss usage */
    u64 acct_vm_mem1;    /* accumulated virtual memory usage */
    cputime_t acct_timexpd;    /* stime + utime since last update */
#endif
#ifdef CONFIG_CPUSETS
    nodemask_t mems_allowed;    /* Protected by alloc_lock */
    seqcount_t mems_allowed_seq;    /* Seqence no to catch updates */
    int cpuset_mem_spread_rotor;
    int cpuset_slab_spread_rotor;
#endif
#ifdef CONFIG_CGROUPS
    /* Control Group info protected by css_set_lock */
    struct css_set __rcu *cgroups;
    /* cg_list protected by css_set_lock and tsk->alloc_lock */
    struct list_head cg_list;
#endif
#ifdef CONFIG_FUTEX
    struct robust_list_head __user *robust_list;
#ifdef CONFIG_COMPAT
    struct compat_robust_list_head __user *compat_robust_list;
#endif
    struct list_head pi_state_list;
    struct futex_pi_state *pi_state_cache;
#endif
#ifdef CONFIG_PERF_EVENTS
    struct perf_event_context *perf_event_ctxp[perf_nr_task_contexts];
    struct mutex perf_event_mutex;
    struct list_head perf_event_list;
#endif
#ifdef CONFIG_DEBUG_PREEMPT
    unsigned long preempt_disable_ip;
#endif
#ifdef CONFIG_NUMA
    struct mempolicy *mempolicy;    /* Protected by alloc_lock */
    short il_next;
    short pref_node_fork;
#endif
#ifdef CONFIG_NUMA_BALANCING
    int numa_scan_seq;
    unsigned int numa_scan_period;
    unsigned int numa_scan_period_max;
    int numa_preferred_nid;
    unsigned long numa_migrate_retry;
    u64 node_stamp;            /* migration stamp  */
    u64 last_task_numa_placement;
    u64 last_sum_exec_runtime;
    struct callback_head numa_work;

    struct list_head numa_entry;
    struct numa_group *numa_group;

    /*
     * numa_faults is an array split into four regions:
     * faults_memory, faults_cpu, faults_memory_buffer, faults_cpu_buffer
     * in this precise order.
     *
     * faults_memory: Exponential decaying average of faults on a per-node
     * basis. Scheduling placement decisions are made based on these
     * counts. The values remain static for the duration of a PTE scan.
     * faults_cpu: Track the nodes the process was running on when a NUMA
     * hinting fault was incurred.
     * faults_memory_buffer and faults_cpu_buffer: Record faults per node
     * during the current scan window. When the scan completes, the counts
     * in faults_memory and faults_cpu decay and these values are copied.
     */
    unsigned long *numa_faults;
    unsigned long total_numa_faults;

    /*
     * numa_faults_locality tracks if faults recorded during the last
     * scan window were remote/local or failed to migrate. The task scan
     * period is adapted based on the locality of the faults with different
     * weights depending on whether they were shared or private faults
     */
    unsigned long numa_faults_locality[3];

    unsigned long numa_pages_migrated;
#endif /* CONFIG_NUMA_BALANCING */

#ifdef CONFIG_ARCH_WANT_BATCHED_UNMAP_TLB_FLUSH
    struct tlbflush_unmap_batch tlb_ubc;
#endif

    struct rcu_head rcu;

    /*
     * cache last used pipe for splice
     */
    struct pipe_inode_info *splice_pipe;

    struct page_frag task_frag;

#ifdef    CONFIG_TASK_DELAY_ACCT
    struct task_delay_info *delays;
#endif
#ifdef CONFIG_FAULT_INJECTION
    int make_it_fail;
#endif
    /*
     * when (nr_dirtied >= nr_dirtied_pause), it's time to call
     * balance_dirty_pages() for some dirty throttling pause
     */
    int nr_dirtied;
    int nr_dirtied_pause;
    unsigned long dirty_paused_when; /* start of a write-and-pause period */

#ifdef CONFIG_LATENCYTOP
    int latency_record_count;
    struct latency_record latency_record[LT_SAVECOUNT];
#endif
    /*
     * time slack values; these are used to round up poll() and
     * select() etc timeout values. These are in nanoseconds.
     */
    unsigned long timer_slack_ns;
    unsigned long default_timer_slack_ns;

#ifdef CONFIG_KASAN
    unsigned int kasan_depth;
#endif
#ifdef CONFIG_FUNCTION_GRAPH_TRACER
    /* Index of current stored address in ret_stack */
    int curr_ret_stack;
    /* Stack of return addresses for return function tracing */
    struct ftrace_ret_stack    *ret_stack;
    /* time stamp for last schedule */
    unsigned long long ftrace_timestamp;
    /*
     * Number of functions that haven't been traced
     * because of depth overrun.
     */
    atomic_t trace_overrun;
    /* Pause for the tracing */
    atomic_t tracing_graph_pause;
#endif
#ifdef CONFIG_TRACING
    /* state flags for use by tracers */
    unsigned long trace;
    /* bitmask and counter of trace recursion */
    unsigned long trace_recursion;
#endif /* CONFIG_TRACING */
#ifdef CONFIG_MEMCG
    struct mem_cgroup *memcg_in_oom;
    gfp_t memcg_oom_gfp_mask;
    int memcg_oom_order;

    /* number of pages to reclaim on returning to userland */
    unsigned int memcg_nr_pages_over_high;
#endif
#ifdef CONFIG_UPROBES
    struct uprobe_task *utask;
#endif
#if defined(CONFIG_BCACHE) || defined(CONFIG_BCACHE_MODULE)
    unsigned int    sequential_io;
    unsigned int    sequential_io_avg;
#endif
#ifdef CONFIG_DEBUG_ATOMIC_SLEEP
    unsigned long    task_state_change;
#endif
    int pagefault_disabled;
/* CPU-specific state of this task */
    struct thread_struct thread;
/*
 * WARNING: on x86, 'thread_struct' contains a variable-sized
 * structure.  It *MUST* be at the end of 'task_struct'.
 *
 * Do not put anything below here!
 */
};
```
