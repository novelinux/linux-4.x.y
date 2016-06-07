do_fork - kernel/fork.c
========================================

参数
----------------------------------------

```
/*
 *  Ok, this is the main fork-routine.
 *
 * It copies the process, and if successful kick-starts
 * it and waits for it to finish using the VM if required.
 */
long do_fork(unsigned long clone_flags,
          unsigned long stack_start,
          struct pt_regs *regs,
          unsigned long stack_size,
          int __user *parent_tidptr,
          int __user *child_tidptr)
{
```

该函数需要下列参数:


```
    struct task_struct *p;
    int trace = 0;
    long nr;

    /*
     * Do some preliminary argument and permissions checking before we
     * actually start allocating stuff
     */
    if (clone_flags & CLONE_NEWUSER) {
        if (clone_flags & CLONE_THREAD)
            return -EINVAL;
        /* hopefully this check will go away when userns support is
         * complete
         */
        if (!capable(CAP_SYS_ADMIN) || !capable(CAP_SETUID) ||
                !capable(CAP_SETGID))
            return -EPERM;
    }

    /*
     * Determine whether and which event to report to ptracer.  When
     * called from kernel_thread or CLONE_UNTRACED is explicitly
     * requested, no event is reported; otherwise, report if the event
     * for the type of forking is enabled.
     */
    if (likely(user_mode(regs)) && !(clone_flags & CLONE_UNTRACED)) {
        if (clone_flags & CLONE_VFORK)
            trace = PTRACE_EVENT_VFORK;
        else if ((clone_flags & CSIGNAL) != SIGCHLD)
            trace = PTRACE_EVENT_CLONE;
        else
            trace = PTRACE_EVENT_FORK;

        if (likely(!ptrace_event_enabled(current, trace)))
            trace = 0;
    }
```

copy_process
----------------------------------------

```
    p = copy_process(clone_flags, stack_start, regs, stack_size,
             child_tidptr, NULL, trace);
```



do_fork以调用copy_process开始，后者执行生成新进程的实际工作，并根据指定的标志重用父进程的数据。
在子进程生成之后，内核必须执行下列收尾操作：

1.task_pid_vnr
----------------------------------------

```
    /*
     * Do this prior waking up the new thread - the thread pointer
     * might get invalid after that point, if the thread exits quickly.
     */
    if (!IS_ERR(p)) {
        struct completion vfork;

        trace_sched_process_fork(current, p);

        // 由于fork要返回新进程的PID，因此必须获得PID。如果PID命名空间没有改变，调用task_pid_vnr
        // 获取局部PID即可，因为新旧进程都在同一个命名空间中。
        nr = task_pid_vnr(p);

        // CLONE_PARENT_SETTID将生成线程的PID复制到clone调用指定的用户空间中的某个地址
        // （parent_tidptr，传递到clone的指针）,复制操作在do_fork中执行，此时新线程的
        // task_struct尚未初始化，copy操作尚未创建新线程的数据。
        if (clone_flags & CLONE_PARENT_SETTID)
            put_user(nr, parent_tidptr);

        if (clone_flags & CLONE_VFORK) {
            p->vfork_done = &vfork;
            init_completion(&vfork);
            get_task_struct(p);
        }
```

2.wake_up_new_task
----------------------------------------

在使用wake_up_new_task唤醒新进程时，则是调度器与进程创建逻辑交互的第二个时机,
内核会调用调度类的task_new函数。这提供了一个时机，将新进程加入到相应类的就绪队列中。

```
        // 子进程使用wake_up_new_task唤醒。换言之，即将其task_struct添加到调度器队列。
        // 调度器也有机会对新启动的进程给予特别处理，这使得可以实现一种策略以便新进程
        // 有较高的几率尽快开始运行，另外也可以防止一再地调用fork浪费CPU时间。如果子进程
        // 在父进程之前开始运行，则可以大大地减少复制内存页的工作量，尤其是子进程在fork
        // 之后发出exec调用的情况下。但要记住，将进程排到调度器数据结构中并不意味着该
        // 子进程可以立即开始执行，而是调度器此时起可以选择它运行。
        wake_up_new_task(p);

        /* forking complete and child started to run, tell ptracer */
        if (unlikely(trace))
            ptrace_event(trace, nr);

        if (clone_flags & CLONE_VFORK) {
            if (!wait_for_vfork_done(p, &vfork))
                ptrace_event(PTRACE_EVENT_VFORK_DONE, nr);
        }
    } else {
        nr = PTR_ERR(p);
    }
    return nr;
}
```

do_fork()函数在创建好task_struct和thread_info等数据结构，并设置好子进程用户态和内核态上下文后，
会将这个子进程丢进调度队列里。当有其他线程调用schedule来进行线程切换时，这个创建出来的进程将
有机会被执行。

注意
----------------------------------------

如果使用vfork机制（内核通过设置的CLONE_VFORK标志识别），必须启用子进程的完成机制
（completions mecha-nism）。子进程的task_struct的vfork_done成员即用于该目的。
借助于wait_for_vfork_done函数，父进程在该变量上进入睡眠状态，直至子进程退出。
在进程终止（或用execve启动新应用程序）时，内核自动调用com-plete（vfork_done）。
这会唤醒所有因该变量睡眠的进程。通过采用这种方法，内核可以确保使用vfork生成的
子进程的父进程会一直处于不活动状态，直至子进程退出或执行一个新的程序。父进程的
临时睡眠状态，也确保了两个进程不会彼此干扰或操作对方的地址空间。

流程图
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/fork.c/res/do_fork.jpg
