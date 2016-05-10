rest_init - init/main.c
========================================

```
static noinline void __init_refok rest_init(void)
{
    int pid;
    const struct sched_param param = { .sched_priority = 1 };
```

1.rcu_scheduler_starting
----------------------------------------

```
    rcu_scheduler_starting();
```

2.kernel_thread - kernel_init
----------------------------------------

调用kernel_thread函数可启动一个内核线程。其定义是特定于体系结构的，但原型总是相同的。

```
    /*
     * We need to spawn init first so that it obtains pid 1, however
     * the init task will end up wanting to create kthreads, which, if
     * we schedule it before we create kthreadd, will OOPS.
     */
    kernel_thread(kernel_init, NULL, CLONE_FS | CLONE_SIGHAND);
```

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/kernel/process.c/kernel_thread.md

通过kernel_thread函数启动了一个内核子线程之后，最后跳转到对应的入口函数kernel_init中去执行.

### kernel_init

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/init/main.c/kernel_init.md

3.kthreadd
----------------------------------------

```
    numa_default_policy();
    pid = kernel_thread(kthreadd, NULL, CLONE_FS | CLONE_FILES);
    rcu_read_lock();
    kthreadd_task = find_task_by_pid_ns(pid, &init_pid_ns);
    rcu_read_unlock();
    sched_setscheduler_nocheck(kthreadd_task, SCHED_FIFO, &param);
    complete(&kthreadd_done);

    /*
     * The boot idle thread must execute schedule()
     * at least once to get things moving:
     */
    init_idle_bootup_task(current);
    schedule_preempt_disabled();
    /* Call into cpu_idle with preempt disabled */
    cpu_idle();
}
```
