copy_process - kernel/fork.c
========================================

在do_fork中大多数工作是由copy_process函数完成的.

1.检查标志
----------------------------------------

```
/*
 * This creates a new process as a copy of the old one,
 * but does not actually start it yet.
 *
 * It copies the registers, and all the appropriate
 * parts of the process environment (as per the clone
 * flags). The actual kick-off is left to the caller.
 */
static struct task_struct *copy_process(unsigned long clone_flags,
                    unsigned long stack_start,
                    struct pt_regs *regs,
                    unsigned long stack_size,
                    int __user *child_tidptr,
                    struct pid *pid,
                    int trace)
{
    int retval;
    struct task_struct *p;
    int cgroup_callbacks_done = 0;

    if ((clone_flags & (CLONE_NEWNS|CLONE_FS)) == (CLONE_NEWNS|CLONE_FS))
        return ERR_PTR(-EINVAL);

    /*
     * Thread groups must share signals as well, and detached threads
     * can only be started up within the thread group.
     */
     /* 在用CLONE_THREAD创建一个线程时，必须用CLONE_SIGHAND激活信号共享。
      * 通常情况下，一个信号无法发送到线程组中的各个线程。*/
    if ((clone_flags & CLONE_THREAD) && !(clone_flags & CLONE_SIGHAND))
        return ERR_PTR(-EINVAL);

    /*
     * Shared signal handlers imply shared VM. By way of the above,
     * thread groups also imply shared VM. Blocking this case allows
     * for various simplifications in other code.
     */
     /* 只有在父子进程之间共享虚拟地址空间时（CLONE_VM），才能提供共享的信号处理程序。
      * 因此类似的想法是，要想达到同样的效果，线程也必须与父进程共享地址空间。
      */
    if ((clone_flags & CLONE_SIGHAND) && !(clone_flags & CLONE_VM))
        return ERR_PTR(-EINVAL);

    /*
     * Siblings of global init remain as zombies on exit since they are
     * not reaped by their parent (swapper). To solve this and to avoid
     * multi-rooted process trees, prevent global and container-inits
     * from creating siblings.
     */
    if ((clone_flags & CLONE_PARENT) &&
                current->signal->flags & SIGNAL_UNKILLABLE)
        return ERR_PTR(-EINVAL);
```

### ERR_PTR

Linux有时候在操作成功时需要返回指针，而在失败时则返回错误码。遗憾的是，C语言每个函数只允许一个
直接的返回值，因此任何有关可能错误的信息都必须编码到指针中。虽然一般而言指针可以指向内存中的
任意位置，而Linux支持的每个体系结构的虚拟地址空间中都有一个从虚拟地址0到至少4 KiB的区域，该
区域中没有任何有意义的信息。因此内核可以重用该地址范围来编码错误码。如果fork的返回值指向前述
的地址范围内部，那么该调用就失败了，其原因可以由指针的数值判断。ERR_PTR是一个辅助宏，用于将
数值常数(例如EINVAL，非法操作)编码为指针:

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/err.h/README.md

2.security_task_create
----------------------------------------

```
    retval = security_task_create(clone_flags);
    if (retval)
        goto fork_out;
```

3.dup_task_struct
----------------------------------------

dup_task_struct来建立父进程task_struct的副本。用于子进程的新的task_struct实例可以在任何空闲的
内核内存位置分配.父子进程的task_struct实例只有一个成员不同：新进程分配了一个新的核心态栈，
即task_struct->stack。通常栈和thread_info一同保存在一个联合中，thread_info保存了线程所需的
所有特定于处理器的底层信息。

例如init_task的相关信息:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/init_task.c

```
    retval = -ENOMEM;
    p = dup_task_struct(current);
    if (!p)
        goto fork_out;
```

其中,current指向当前正在运行的进程，其获取方式如下:

https://github.com/novelinux/linux-4.x.y/tree/master/include/asm-generic/current.h/current.h.md

dup_task_struct的具体实现如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/fork.c/dup_task_struct.md

4.检查当前特定用户进程数
----------------------------------------

在dup_task_struct成功之后,内核会检查当前的特定用户在创建新进程之后，是否超出了允许的最大进程数目:
拥有当前进程的用户，其资源计数器保存一个user_struct实例中，可通过task_struct->real_cred->user
访问，特定用户当前持有进程的数目保存在user_struct->processes。如果该值超出rlimit设置的限制，
则放弃创建进程，除非当前用户是root用户或分配了特别的权限（CAP_SYS_ADMIN或CAP_SYS_RESOURCE）。
检测root用户很有趣：每个PID命名空间都有各自的root用户。上述检测必须考虑这一点。

```
    ftrace_graph_init_task(p);

    rt_mutex_init_task(p);

#ifdef CONFIG_PROVE_LOCKING
    DEBUG_LOCKS_WARN_ON(!p->hardirqs_enabled);
    DEBUG_LOCKS_WARN_ON(!p->softirqs_enabled);
#endif
    retval = -EAGAIN;
    if (atomic_read(&p->real_cred->user->processes) >=
            task_rlimit(p, RLIMIT_NPROC)) {
        if (!capable(CAP_SYS_ADMIN) && !capable(CAP_SYS_RESOURCE) &&
            p->real_cred->user != INIT_USER)
            goto bad_fork_free;
    }
```

5.共享资源
----------------------------------------

接下来会调用许多形如copy_xyz的例程，以便复制或共享特定的内核子系统的资源。task_struct
包含了一些指针，指向具体数据结构的实例，描述了可共享或可复制的资源。由于子进程的task_struct
是从父进程的task_struct精确复制而来，因此相关的指针最初都指向同样的资源，或者说同样的具体资源
实例，如图所示:

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/kernel/fork.c/res/share_res.jpg

假定我们有两个资源：res_abc和res_def。最初父子进程的task_struct中的对应指针都指向了资源的同一个
实例，即内存中特定的数据结构。如果CLONE_ABC置位，则两个进程会共享res_abc。此外，为防止与资源实例
关联的内存空间释放过快，还需要对实例的引用计数器加1，只有进程不再使用内存时，才能释放。如果
父进程或子进程修改了共享资源，则变化在两个进程中都可以看到。如果CLONE_ABC没有置位，接下来会为
子进程创建res_abc的一份副本，新副本的资源计数器初始化为1。因此在这种情况下，如果父进程或子进程
修改了资源，变化不会传播到另一个进程。通常，设置的CLONE标志越少，需要完成的工作越少。但多设置
一些标志，则使得父子进程有更多机会相互操作彼此的数据结构，在编写应用程序时必须考虑到这一点。
判断资源是共享还是复制需要通过许多辅助例程完成，每个辅助例程对应一种资源。

```
    current->flags &= ~PF_NPROC_EXCEEDED;

    retval = copy_creds(p, clone_flags);
    if (retval < 0)
        goto bad_fork_free;

    /*
     * If multiple threads are within copy_process(), then this check
     * triggers too late. This doesn't hurt, the check is only there
     * to stop root fork bombs.
     */
    retval = -EAGAIN;
    if (nr_threads >= max_threads)
        goto bad_fork_cleanup_count;

    if (!try_module_get(task_thread_info(p)->exec_domain->module))
        goto bad_fork_cleanup_count;

    p->did_exec = 0;
    delayacct_tsk_init(p);    /* Must remain after dup_task_struct() */
    copy_flags(clone_flags, p);

    // 内核必须填好task_struct中对父子进程不同的各个成员。包含下列一些：
    // A.task_struct中包含的各个链表元素，例如sibling和children；
    // B.间隔定时器成员cpu_timers
    // C.待决信号列表（pending），
    INIT_LIST_HEAD(&p->children);
    INIT_LIST_HEAD(&p->sibling);
    rcu_copy_process(p);
    p->vfork_done = NULL;
    spin_lock_init(&p->alloc_lock);

    init_sigpending(&p->pending);

    p->utime = p->stime = p->gtime = 0;
    p->utimescaled = p->stimescaled = 0;
#ifndef CONFIG_VIRT_CPU_ACCOUNTING
    p->prev_utime = p->prev_stime = 0;
#endif
#if defined(SPLIT_RSS_COUNTING)
    memset(&p->rss_stat, 0, sizeof(p->rss_stat));
#endif

    p->default_timer_slack_ns = current->timer_slack_ns;

    task_io_accounting_init(&p->ioac);
    acct_clear_integrals(p);

    posix_cpu_timers_init(p);

    do_posix_clock_monotonic_gettime(&p->start_time);
    p->real_start_time = p->start_time;
    monotonic_to_bootbased(&p->real_start_time);
    p->io_context = NULL;
    p->audit_context = NULL;
    if (clone_flags & CLONE_THREAD)
        threadgroup_change_begin(current);
    cgroup_fork(p);
#ifdef CONFIG_NUMA
    p->mempolicy = mpol_dup(p->mempolicy);
    if (IS_ERR(p->mempolicy)) {
        retval = PTR_ERR(p->mempolicy);
        p->mempolicy = NULL;
        goto bad_fork_cleanup_cgroup;
    }
    mpol_fix_fork_child_flag(p);
#endif
#ifdef CONFIG_CPUSETS
    p->cpuset_mem_spread_rotor = NUMA_NO_NODE;
    p->cpuset_slab_spread_rotor = NUMA_NO_NODE;
    seqcount_init(&p->mems_allowed_seq);
#endif
#ifdef CONFIG_TRACE_IRQFLAGS
    p->irq_events = 0;
#ifdef __ARCH_WANT_INTERRUPTS_ON_CTXSW
    p->hardirqs_enabled = 1;
#else
    p->hardirqs_enabled = 0;
#endif
    p->hardirq_enable_ip = 0;
    p->hardirq_enable_event = 0;
    p->hardirq_disable_ip = _THIS_IP_;
    p->hardirq_disable_event = 0;
    p->softirqs_enabled = 1;
    p->softirq_enable_ip = _THIS_IP_;
    p->softirq_enable_event = 0;
    p->softirq_disable_ip = 0;
    p->softirq_disable_event = 0;
    p->hardirq_context = 0;
    p->softirq_context = 0;
#endif
#ifdef CONFIG_LOCKDEP
    p->lockdep_depth = 0; /* no locks held yet */
    p->curr_chain_key = 0;
    p->lockdep_recursion = 0;
#endif

#ifdef CONFIG_DEBUG_MUTEXES
    p->blocked_on = NULL; /* not blocked yet */
#endif
#ifdef CONFIG_CGROUP_MEM_RES_CTLR
    p->memcg_batch.do_batch = 0;
    p->memcg_batch.memcg = NULL;
#endif

    /* Perform scheduler related setup. Assign this task to a CPU. */
    // 每当使用fork系统调用或其变体之一建立新进程时，调度器有机会用sched_fork函数挂钩到该进程。
    // 在单处理器系统上，该函数实质上执行3个操作：
    // 1.初始化新进程与调度相关的字段;
    // 2.建立数据结构（相当简单直接）;
    // 3.确定进程的动态优先级。
    sched_fork(p);

    retval = perf_event_init_task(p);
    if (retval)
        goto bad_fork_cleanup_policy;
    retval = audit_alloc(p);
    if (retval)
        goto bad_fork_cleanup_policy;

    /* copy all the process information */
    // 如果COPY_SYSVSEM置位，则copy_semundo使用父进程的System V信号量。
    retval = copy_semundo(clone_flags, p);
    if (retval)
        goto bad_fork_cleanup_audit;

    // 如果CLONE_FILES置位，则copy_files使用父进程的文件描述符；否则创建新的files结构，
    // 其中包含的信息与父进程相同。该信息的修改可以独立于原结构。
    retval = copy_files(clone_flags, p);
    if (retval)
        goto bad_fork_cleanup_semundo;

    // 如果CLONE_FS置位，则copy_fs使用父进程的文件系统上下文（task_struct->fs）。这是一个
    // fs_struct类型的结构，包含了诸如根目录、进程的当前工作目录之类的信息
    retval = copy_fs(clone_flags, p);
    if (retval)
        goto bad_fork_cleanup_files;

    // 如果CLONE_SIGHAND或CLONE_THREAD置位，则copy_sighand使用父进程的信号处理程序。
    retval = copy_sighand(clone_flags, p);
    if (retval)
        goto bad_fork_cleanup_fs;

    // 如果CLONE_THREAD置位，则copy_signal与父进程共同使用信号处理中不特定于处理程序的部分
    retval = copy_signal(clone_flags, p);
    if (retval)
        goto bad_fork_cleanup_sighand;

    // 如果COPY_MM置位，则copy_mm让父进程和子进程共享同一地址空间。在这种情况下，两个进程
    // 使用同一个mm_struct实例，task_struct->mm指针即指向该实例,如果copy_mm没有置位，并不
    // 意味着需要复制父进程的整个地址空间。内核确实会创建页表的一份副本，但并不复制页的实际内容。
    // 这是使用COW机制完成的，仅当其中一个进程将数据写入页时，才会进行实际复制。
    retval = copy_mm(clone_flags, p);
    if (retval)
        goto bad_fork_cleanup_signal;

    // copy_namespaces有特别的调用语义。它用于建立子进程的命名空间。几个控制与父进程共享何种
    // 命名空间的CLONE_NEWxyz标志，但其语义与所有其他标志都相反。如果没有指定CLONE_NEWxyz，
    // 则与父进程共享相应的命名空间，否则创建一个新的命名空间。copy_namespaces相当于调度程序，
    // 对每个可能的命名空间，分别执行对应的复制例程。但各个具体的复制例程就没什么趣味了，因为
    // 本质上就是复制数据或通过引用计数的管理来共享现存的实例.
    retval = copy_namespaces(clone_flags, p);
    if (retval)
        goto bad_fork_cleanup_mm;

    retval = copy_io(clone_flags, p);
    if (retval)
        goto bad_fork_cleanup_namespaces;

    retval = copy_thread(clone_flags, stack_start, stack_size, p, regs);
    if (retval)
        goto bad_fork_cleanup_io;
```

### copy_thread

copy_thread与这里讨论的所有其他复制操作都大不相同，这是一个特定于体系结构的函数，用于复制进程
中特定于线程（thread-specific）的数据。这里的特定于线程并不是指某个CLONE标志，也不是指操作对
线程而非整个进程执行。其语义无非是指复制执行上下文中特定于体系结构的所有数据（内核中名词线程
通常用于多个含义）。重要的是填充task_struct->thread的各个成员。这是一个thread_struct类型的结构，
其定义是体系结构相关的。它包含了所有寄存器（和其他信息），内核在进程之间切换时需要保存和恢复进程
的内容，该结构可用于此。为理解各个thread_struct结构的布局，需要深入了解各种CPU的相关知识。

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/arch/arm/kernel/process.c/copy_thread.md

6.设置ID
----------------------------------------

pid_nr函数对给定的pid实例计算全局数值PID。

```
    if (pid != &init_struct_pid) {
        retval = -ENOMEM;
        // 在建立一个新进程时，进程可能在多个命名空间中是可见的。对每个这样的命名空间，都需要
        // 生成一个局部PID。这是在alloc_pid中处理的
        pid = alloc_pid(p->nsproxy->pid_ns);
        if (!pid)
            goto bad_fork_cleanup_io;
    }

    // 在用之前描述的机制为进程分配一个新的pid实例之后，则保存在task_struct中。对于线程，
    // 线程组ID与分支进程（即调用fork/clone的进程）pid相同：
    p->pid = pid_nr(pid);
    p->tgid = p->pid;
    if (clone_flags & CLONE_THREAD)
        p->tgid = current->tgid;

    // CLONE_CHILD_SETTID首先会将另一个传递到clone的用户空间指针（child_tidptr）保存在新进程的
    // task_struct中。在新进程第一次执行时，内核会调用schedule_tail函数将当前PID复制到child_tidptr
    p->set_child_tid = (clone_flags & CLONE_CHILD_SETTID) ? child_tidptr : NULL;
    /*
     * Clear TID on mm_release()?
     */
    // CLONE_CHILD_CLEARTID首先会在copy_process中将用户空间指针child_tidptr保存在task_struct中，
    // 这次是另一个不同的成员。在进程终止时，将0写入clear_child_tid指定的地址。
    p->clear_child_tid = (clone_flags & CLONE_CHILD_CLEARTID) ? child_tidptr : NULL;

#ifdef CONFIG_BLOCK
    p->plug = NULL;
#endif
#ifdef CONFIG_FUTEX
    p->robust_list = NULL;
#ifdef CONFIG_COMPAT
    p->compat_robust_list = NULL;
#endif
    INIT_LIST_HEAD(&p->pi_state_list);
    p->pi_state_cache = NULL;
#endif
    /*
     * sigaltstack should be cleared when sharing the same VM
     */
    if ((clone_flags & (CLONE_VM|CLONE_VFORK)) == CLONE_VM)
        p->sas_ss_sp = p->sas_ss_size = 0;

    /*
     * Syscall tracing and stepping should be turned off in the
     * child regardless of CLONE_PTRACE.
     */
    user_disable_single_step(p);
    clear_tsk_thread_flag(p, TIF_SYSCALL_TRACE);
#ifdef TIF_SYSCALL_EMU
    clear_tsk_thread_flag(p, TIF_SYSCALL_EMU);
#endif
    clear_all_latency_tracing(p);

    /* ok, now we should be set up.. */
    if (clone_flags & CLONE_THREAD)
        p->exit_signal = -1;
    else if (clone_flags & CLONE_PARENT)
        p->exit_signal = current->group_leader->exit_signal;
    else
        p->exit_signal = (clone_flags & CSIGNAL);

    p->pdeath_signal = 0;
    p->exit_state = 0;

    p->nr_dirtied = 0;
    p->nr_dirtied_pause = 128 >> (PAGE_SHIFT - 10);
    p->dirty_paused_when = 0;

    /*
     * Ok, make it visible to the rest of the system.
     * We dont wake it up yet.
     */
    p->group_leader = p;
    INIT_LIST_HEAD(&p->thread_group);

    /* Now that the task is set up, run cgroup callbacks if
     * necessary. We need to run them before the task is visible
     * on the tasklist. */
    cgroup_fork_callbacks(p);
    cgroup_callbacks_done = 1;

    /* Need tasklist lock for parent etc handling! */
    write_lock_irq(&tasklist_lock);

    /* CLONE_PARENT re-uses the old parent */
    // 对普通进程，父进程是分支进程。对于线程来说有些不同：由于线程被视为分支进程内部的第二
    // （或第三、第四，等等）个执行序列，其父进程应是分支进程的父进程。
    if (clone_flags & (CLONE_PARENT|CLONE_THREAD)) {
        p->real_parent = current->real_parent;
        p->parent_exec_id = current->parent_exec_id;
    } else {
        p->real_parent = current;
        p->parent_exec_id = current->self_exec_id;
    }

    spin_lock(&current->sighand->siglock);

    /*
     * Process group and session signals need to be delivered to just the
     * parent before the fork or both the parent and the child after the
     * fork. Restart if a signal comes in before we add the new process to
     * it's process group.
     * A fatal signal pending means that current will exit, so the new
     * thread can't slip out of an OOM kill (or normal SIGKILL).
    */
    recalc_sigpending();
    if (signal_pending(current)) {
        spin_unlock(&current->sighand->siglock);
        write_unlock_irq(&tasklist_lock);
        retval = -ERESTARTNOINTR;
        goto bad_fork_free_pid;
    }

    // 非线程的普通进程可通过设置CLONE_PARENT触发同样的行为。对线程来说还需要另一个校正，
    // 即普通进程的线程组组长是进程本身。对线程来说，其组长是当前进程的组长.
    if (clone_flags & CLONE_THREAD) {
        current->signal->nr_threads++;
        atomic_inc(&current->signal->live);
        atomic_inc(&current->signal->sigcnt);
        p->group_leader = current->group_leader;
        list_add_tail_rcu(&p->thread_group, &p->group_leader->thread_group);
    }

    if (likely(p->pid)) {
        ptrace_init_task(p, (clone_flags & CLONE_PTRACE) || trace);

        if (thread_group_leader(p)) {
            if (is_child_reaper(pid))
                p->nsproxy->pid_ns->child_reaper = p;

            p->signal->leader_pid = pid;
            p->signal->tty = tty_kref_get(current->signal->tty);
            attach_pid(p, PIDTYPE_PGID, task_pgrp(current));
            attach_pid(p, PIDTYPE_SID, task_session(current));
            list_add_tail(&p->sibling, &p->real_parent->children);
            list_add_tail_rcu(&p->tasks, &init_task.tasks);
            __this_cpu_inc(process_counts);
        }
        // 假如已经分配了struct pid的一个新实例，并设置用于给定的ID类型。它会如下附加到task_struct
        attach_pid(p, PIDTYPE_PID, pid);
        nr_threads++;
    }

    total_forks++;
    spin_unlock(&current->sighand->siglock);
    write_unlock_irq(&tasklist_lock);
    proc_fork_connector(p);
    cgroup_post_fork(p);
    if (clone_flags & CLONE_THREAD)
        threadgroup_change_end(current);
    perf_event_fork(p);

    trace_task_newtask(p, clone_flags);

    return p;

    ...
    return ERR_PTR(retval);
}
```

有关进程id相关操作如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/sched.h/id/README.md

流程图
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/kernel/fork.c/res/copy_process.jpg
