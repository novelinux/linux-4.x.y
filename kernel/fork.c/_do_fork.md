_do_fork
========================================

Code Flow
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/fork.c/res/do_fork.jpg

Arguments
----------------------------------------

path: kernel/fork.c
```
/*
 *  Ok, this is the main fork-routine.
 *
 * It copies the process, and if successful kick-starts
 * it and waits for it to finish using the VM if required.
 */
long _do_fork(unsigned long clone_flags,
          unsigned long stack_start,
          unsigned long stack_size,
          int __user *parent_tidptr,
          int __user *child_tidptr,
          unsigned long tls)
{
    struct task_struct *p;
    int trace = 0;
    long nr;
```

* clone_flags

是一个标志集合，用来指定控制复制过程的一些属性。最低字节指定
了在子进程终止时被发给父进程的信号号码。其余的高位字节保存了
各种常数。

* start_stack

是用户状态下栈的起始地址。

* stack_size

是用户状态下栈的大小。该参数通常是不必要的，设置为0。

* parent_tidptr vs child_tidptr

是指向用户空间中地址的两个指针，分别指向父子进程的TID。

trace
----------------------------------------

```
    /*
     * Determine whether and which event to report to ptracer.  When
     * called from kernel_thread or CLONE_UNTRACED is explicitly
     * requested, no event is reported; otherwise, report if the event
     * for the type of forking is enabled.
     */
    if (!(clone_flags & CLONE_UNTRACED)) {
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
    p = copy_process(clone_flags, stack_start, stack_size,
             child_tidptr, NULL, trace, tls);
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/fork.c/copy_process.md

start new thread
----------------------------------------

do_fork以调用copy_process开始，后者执行生成新进程的实际工作，
并根据指定的标志重用父进程的数据。

### get_task_pid

```
    /*
     * Do this prior waking up the new thread - the thread pointer
     * might get invalid after that point, if the thread exits quickly.
     */
    if (!IS_ERR(p)) {
        struct completion vfork;
        struct pid *pid;

        trace_sched_process_fork(current, p);

        pid = get_task_pid(p, PIDTYPE_PID);
```

### pid_vnr

```
        nr = pid_vnr(pid);

        if (clone_flags & CLONE_PARENT_SETTID)
            put_user(nr, parent_tidptr);

        if (clone_flags & CLONE_VFORK) {
            p->vfork_done = &vfork;
            init_completion(&vfork);
            get_task_struct(p);
        }
```

### wake_up_new_task

在使用wake_up_new_task唤醒新进程时，则是调度器与进程创建逻辑
交互的第二个时机,内核会调用调度类的task_new函数。这提供了一个
时机，将新进程加入到相应类的就绪队列中。

子进程使用wake_up_new_task唤醒。换言之，即将其task_struct添加到
调度器队列。调度器也有机会对新启动的进程给予特别处理，这使得可以
实现一种策略以便新进程有较高的几率尽快开始运行，另外也可以防止
一再地调用fork浪费CPU时间。如果子进程在父进程之前开始运行，则
可以大大地减少复制内存页的工作量，尤其是子进程在fork之后发出
exec调用的情况下。但要记住，将进程排到调度器数据结构中并不意味
着该子进程可以立即开始执行，而是调度器此时起可以选择它运行。

```
        wake_up_new_task(p);

        /* forking complete and child started to run, tell ptracer */
        if (unlikely(trace))
            ptrace_event_pid(trace, pid);

        if (clone_flags & CLONE_VFORK) {
            if (!wait_for_vfork_done(p, &vfork))
                ptrace_event_pid(PTRACE_EVENT_VFORK_DONE, pid);
        }
```

### put_pid

```
        put_pid(pid);
    } else {
        nr = PTR_ERR(p);
    }
    return nr;
}
```

do_fork()函数在创建好task_struct和thread_info等数据结构，并设置
好子进程用户态和内核态上下文后，会将这个子进程丢进调度队列里。
当有其他线程调用schedule来进行线程切换时，这个创建出来的进程将
有机会被执行。