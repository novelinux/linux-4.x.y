task_struct
========================================

Linux内核涉及进程和程序的所有算法都围绕一个名为task_struct的数据结构建立，
该结构定义在include/sched.h中。这是系统中主要的一个结构。task_struct包含很多成员，
将进程与各个内核子系统联系起来，下文会逐一讨论。

path: include/linux/sched.h
```
struct task_struct {
    volatile long state;    /* -1 unrunnable, 0 runnable, >0 stopped */
    void *stack;
    atomic_t usage;
    unsigned int flags;    /* per process flags, defined below */
    unsigned int ptrace;

#ifdef CONFIG_SMP
    struct llist_node wake_entry;
    int on_cpu;
    struct task_struct *last_wakee;
    unsigned long wakee_flips;
    unsigned long wakee_flip_decay_ts;

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
#endif /* #ifdef CONFIG_PREEMPT_RCU */
#ifdef CONFIG_PREEMPT_RCU
    struct rcu_node *rcu_blocked_node;
#endif /* #ifdef CONFIG_PREEMPT_RCU */
#ifdef CONFIG_TASKS_RCU
    unsigned long rcu_tasks_nvcsw;
    bool rcu_tasks_holdout;
    struct list_head rcu_tasks_holdout_list;
    int rcu_tasks_idle_cpu;
#endif /* #ifdef CONFIG_TASKS_RCU */

#if defined(CONFIG_SCHEDSTATS) || defined(CONFIG_TASK_DELAY_ACCT)
    struct sched_info sched_info;
#endif

    struct list_head tasks;
#ifdef CONFIG_SMP
    struct plist_node pushable_tasks;
    struct rb_node pushable_dl_tasks;
#endif

    struct mm_struct *mm, *active_mm;
#ifdef CONFIG_COMPAT_BRK
    unsigned brk_randomized:1;
#endif
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
    unsigned int jobctl;    /* JOBCTL_*, siglock protected */

    /* Used for emulating ABI behavior of previous Linux versions */
    unsigned int personality;

    unsigned in_execve:1;    /* Tell the LSMs that the process is doing an
                 * execve */
    unsigned in_iowait:1;

    /* Revert to default priority/policy when forking */
    unsigned sched_reset_on_fork:1;
    unsigned sched_contributes_to_load:1;

#ifdef CONFIG_MEMCG_KMEM
    unsigned memcg_kmem_skip_account:1;
#endif

    unsigned long atomic_flags; /* Flags needing atomic access. */

    pid_t pid;
    pid_t tgid;

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
    /*
     * children/sibling forms the list of my natural children
     */
    struct list_head children;    /* list of my children */
    struct list_head sibling;    /* linkage in my parent's children list */
    struct task_struct *group_leader;    /* threadgroup leader */

    /*
     * ptraced is the list of tasks this task is using ptrace on.
     * This includes both natural children and PTRACE_ATTACH targets.
     * p->ptrace_entry is p's link on the p->parent->ptraced list.
     */
    struct list_head ptraced;
    struct list_head ptrace_entry;

    /* PID/PID hash table linkage. */
    struct pid_link pids[PIDTYPE_MAX];
    struct list_head thread_group;
    struct list_head thread_node;

    struct completion *vfork_done;        /* for vfork() */
    int __user *set_child_tid;        /* CLONE_CHILD_SETTID */
    int __user *clear_child_tid;        /* CLONE_CHILD_CLEARTID */

    cputime_t utime, stime, utimescaled, stimescaled;
    cputime_t gtime;
#ifndef CONFIG_VIRT_CPU_ACCOUNTING_NATIVE
    struct cputime prev_cputime;
#endif
#ifdef CONFIG_VIRT_CPU_ACCOUNTING_GEN
    seqlock_t vtime_seqlock;
    unsigned long long vtime_snap;
    enum {
        VTIME_SLEEPING = 0,
        VTIME_USER,
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
/* file system info */
    int link_count, total_link_count;
#ifdef CONFIG_SYSVIPC
/* ipc stuff */
    struct sysv_sem sysvsem;
    struct sysv_shm sysvshm;
#endif
#ifdef CONFIG_DETECT_HUNG_TASK
/* hung task detection */
    unsigned long last_switch_count;
#endif
/* CPU-specific state of this task */
    struct thread_struct thread;
/* filesystem information */
    struct fs_struct *fs;
/* open file information */
    struct files_struct *files;
/* namespaces */
    struct nsproxy *nsproxy;
/* signal handlers */
    struct signal_struct *signal;
    struct sighand_struct *sighand;

    sigset_t blocked, real_blocked;
    sigset_t saved_sigmask;    /* restored if set_restore_sigmask() was used */
    struct sigpending pending;

    unsigned long sas_ss_sp;
    size_t sas_ss_size;
    int (*notifier)(void *priv);
    void *notifier_data;
    sigset_t *notifier_mask;
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
     * scan window were remote/local. The task scan period is adapted
     * based on the locality of the faults with different weights
     * depending on whether they were shared or private faults
     */
    unsigned long numa_faults_locality[2];

    unsigned long numa_pages_migrated;
#endif /* CONFIG_NUMA_BALANCING */

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
    struct memcg_oom_info {
        struct mem_cgroup *memcg;
        gfp_t gfp_mask;
        int order;
        unsigned int may_oom:1;
    } memcg_oom;
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
};
```

该结构的内容可以分解为各个部分，每个部分表示进程的一个特定方面。

* 状态和执行信息，如待决信号、使用的二进制格式（和其他系统二进制格式的任何仿真信息）、
  进程ID号（pid）、到父进程及其他有关进程的指针、优先级和程序执行有关的时间信息（例如CPU时间）。
* 有关已经分配的虚拟内存的信息。
* 进程身份凭据，如用户ID、组ID以及权限等。可使用系统调用查询（或修改）这些数据。
* 使用的文件包含程序代码的二进制文件，以及进程所处理的所有文件的文件系统信息，这些都必须保存下来。
* 线程信息记录该进程特定于CPU的运行时间数据（该结构的其余字段与所使用的硬件无关）。
* 在与其他应用程序协作时所需的进程间通信有关的信息。
* 该进程所用的信号处理程序，用于响应到来的信号。

对进程管理的实现特别重要的一些成员
----------------------------------------

### state

指定了进程的当前状态，可使用下列值(这些是预处理器常数，定义在<sched.h>中).

* TASK_RUNNING意味着进程处于可运行状态。这并不意味着已经实际分配了CPU。
  进程可能会一直等到调度器选中它。该状态确保进程可以立即运行，而无需等待外部事件。

* TASK_INTERRUPTIBLE是针对等待某事件或其他资源的睡眠进程设置的。在内核发送信号给
  该进程表明事件已经发生时，进程状态变为TASK_RUNNING，它只要调度器选中该进程即可恢复执行。

* TASK_UNINTERRUPTIBLE用于因内核指示而停用的睡眠进程。它们不能由外部信号唤醒，只能由内核亲自唤醒。

* TASK_STOPPED表示进程特意停止运行，例如，由调试器暂停。

* TASK_TRACED本来不是进程状态，用于从停止的进程中，将当前被调试的那些（使用ptrace机制）与常规的进程区分开来。

### exit_state

* EXIT_ZOMBIE如上所述的僵尸状态。

* EXIT_DEAD状态则是指wait系统调用已经发出，而进程完全从系统移除之前的状态。只有多个线程对同一个进程发出wait调用时，该状态才有意义。

### struct rlimit

Linux提供资源限制(resource limit，rlimit)机制，对进程使用系统资源施加某些限制。
该机制利用了task_struct中的signal_struct中的rlim数组，数组类型为struct rlimit

path: include/uapi/linux/resource.h
```
struct rlimit {
	__kernel_ulong_t	rlim_cur;
	__kernel_ulong_t	rlim_max;
};
```

* rlim_cur是进程当前的资源限制，也称之为软限制（softlimit）。
* rlim_max是该限制的最大容许值，因此也称之为硬限制（hard limit）。

系统调用setrlimit来增减当前限制，但不能超出rlim_max指定的值。getrlimits用于检查当前限制。
rlim数组中的位置标识了受限制资源的类型，这也是内核需要定义预处理器常数，将资源与位置
关联起来的原因。下表列出了可能的常数及其含义。关于如何最佳地运用各种限制，系统程序
设计方面的教科书提供了详细的说明，而setrlimit(2)的手册页详细描述了所有的限制。

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/sched.h/res/rlimit.png

内核在proc文件系统中对每个进程都包含了对应的一个文件，这样就可以查看当前的rlimit值：

```
root@cancro:/proc/1 # cat limits
Limit                     Soft Limit           Hard Limit           Units
Max cpu time              unlimited            unlimited            seconds
Max file size             unlimited            unlimited            bytes
Max data size             unlimited            unlimited            bytes
Max stack size            8388608              unlimited            bytes
Max core file size        0                    unlimited            bytes
Max resident set          unlimited            unlimited            bytes
Max processes             11668                11668                processes
Max open files            1024                 4096                 files
Max locked memory         67108864             67108864             bytes
Max address space         unlimited            unlimited            bytes
Max file locks            unlimited            unlimited            locks
Max pending signals       11668                11668                signals
Max msgqueue size         819200               819200               bytes
Max nice priority         40                   40
Max realtime priority     0                    0
Max realtime timeout      unlimited            unlimited            us
```

### struct nsproxy

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/sched.h/nsproxy/README.md

### id

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/sched.h/id/README.md

### 进程关系

除了源于ID连接的关系之外,内核还负责管理建立在UNIX进程创建模型之上“家族关系”.
相关讨论一般使用下列术语:

* 如果进程A分支形成进程B，进程A称之为父进程而进程B则是子进程。如果进程B再次分支建立另一个进程C，
  进程A和进程C之间有时称之为祖孙关系。
* 如果进程A分支若干次形成几个子进程B1，B2，…，Bn，各个Bi进程之间的关系称之为兄弟关系。

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/sched.h/res/task_relation.jpg

task_struct数据结构提供了两个链表表头，用于实现这些关系：

```
    /*
     * children/sibling forms the list of my natural children
     */
    struct list_head children;    /* list of my children */
    struct list_head sibling;    /* linkage in my parent's children list */
```

* children是链表表头，该链表中保存有进程的所有子进程。
* sibling用于将兄弟进程彼此连接起来。新的子进程置于sibling链表的起始位置，这意味着可以
  重建进程分支的时间顺序。
