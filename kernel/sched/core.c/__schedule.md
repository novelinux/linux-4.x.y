__schedule - kernel/sched/core.c
========================================

在内核中的许多地方，如果要将CPU分配给与当前活动进程不同的另一个进程，都会直接调用主调度器函数
（schedule）。在从系统调用返回之后，内核也会检查当前进程是否设置了重调度标志TIF_NEED_RESCHED，
例如，前述的scheduler_tick就会设置该标志。如果是这样，则内核会调用schedule。该函数假定当前活动
进程一定会被另一个进程取代。

1.__sched前缀
----------------------------------------

该前缀用于可能调用schedule的函数，包括schedule自身。
该前缀目的在于: 将相关函数的代码编译之后，放到目标文件的一个特定的段中，即.sched.text中。
该信息使得内核在显示栈转储或类似信息时，忽略所有与调度有关的调用。由于调度器函数调用不是
普通代码流程的一部分，因此在这种情况下是没有意义的。

```
/*
 * __schedule() is the main scheduler function.
 */
static void __sched __schedule(void)
{
```

2.确定当前就绪队列
----------------------------------------

该函数首先确定当前就绪队列，并在prev中保存一个指向（仍然）活动进程的task_struct的指针。

```
    struct task_struct *prev, *next;
    unsigned long *switch_count;
    struct rq *rq;
    int cpu;

need_resched:
    preempt_disable();
    cpu = smp_processor_id();
    rq = cpu_rq(cpu);
    rcu_note_context_switch(cpu);
    prev = rq->curr;
```

3.选择调度进程
----------------------------------------

```
    schedule_debug(prev);

    if (sched_feat(HRTICK))
        hrtick_clear(rq);

    raw_spin_lock_irq(&rq->lock);

    switch_count = &prev->nivcsw;
    if (prev->state && !(preempt_count() & PREEMPT_ACTIVE)) {
        // 同样因为调度器的模块化结构，大多数工作可以委托给调度类。如果当前进程原来
        // 处于可中断睡眠状态但现在接收到信号，那么它必须再次提升为运行进程。否则，
        // 用相应调度器类的方法使进程停止活动(deactivate_task实质上最终调用了
        // sched_class->dequeue_task)
        if (unlikely(signal_pending_state(prev->state, prev))) {
            prev->state = TASK_RUNNING;
        } else {
            deactivate_task(rq, prev, DEQUEUE_SLEEP);
            prev->on_rq = 0;

            /*
             * If a worker went to sleep, notify and ask workqueue
             * whether it wants to wake up a task to maintain
             * concurrency.
             */
            if (prev->flags & PF_WQ_WORKER) {
                struct task_struct *to_wakeup;

                to_wakeup = wq_worker_sleeping(prev, cpu);
                if (to_wakeup)
                    try_to_wake_up_local(to_wakeup);
            }
        }
        switch_count = &prev->nvcsw;
    }

    pre_schedule(rq, prev);

    if (unlikely(!rq->nr_running))
        idle_balance(cpu, rq);

    // put_prev_task首先通知调度器类当前运行的进程将要被另一个进程代替。要注意，这不等价于把
    // 进程从就绪队列移除，而是提供了一个时机，供执行一些簿记工作并更新统计量。调度类还必须
    // 选择下一个应该执行的进程，该工作由pick_next_task负责：
    put_prev_task(rq, prev);
    next = pick_next_task(rq);
    // 类似于周期性调度器，内核也利用该时机来更新就绪队列的时钟，并清除当前运行进程task_struct
    // 中的重调度标志TIF_NEED_RESCHED。
    clear_tsk_need_resched(prev);
    rq->skip_clock_update = 0;
```

4.context_switch
----------------------------------------

```
    // 不见得必然选择一个新进程。也可能其他进程都在睡眠，当前只有一个进程能够运行，这样它
    // 自然就被留在CPU上。但如果已经选择了一个新进程，那么必须准备并执行硬件级的进程切换。
    if (likely(prev != next)) {
        rq->nr_switches++;
        rq->curr = next;
        ++*switch_count;
        // context_switch一个接口，供访问特定于体系结构的方法，后者负责执行底层上下文切换。
        context_switch(rq, prev, next); /* unlocks the rq */
        /*
         * The context switch have flipped the stack from under us
         * and restored the local variables which were saved when
         * this task called schedule() in the past. prev == current
         * is still correct, but it can be moved to another cpu/rq.
         */
        cpu = smp_processor_id();
        rq = cpu_rq(cpu);
    } else
        raw_spin_unlock_irq(&rq->lock);

    post_schedule(rq);

    // 下述代码片段可能在两个不同的上下文中执行。在没有执行上下文切换时，它在schedule函数的
    // 末尾直接执行。但如果已经执行了上下文切换，当前进程会正好在这以前停止运行，新进程已经
    // 接管了CPU。但稍后在前一进程被再次选择运行时，它会刚好在这一点上恢复执行。在这种情况下，
    // 由于prev不会指向正确的进程，所以需要通过current和test_thread_flag找到当前线程。
    sched_preempt_enable_no_resched();
    if (need_resched())
        goto need_resched;
}
```

### context_switch

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/kernel/sched/core.c/context_switch.md
