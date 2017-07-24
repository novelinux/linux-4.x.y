# process_one_work

```
/**
 * process_one_work - process single work
 * @worker: self
 * @work: work to process
 *
 * Process @work.  This function contains all the logics necessary to
 * process a single work including synchronization against and
 * interaction with other workers on the same cpu, queueing and
 * flushing.  As long as context requirement is met, any worker can
 * call this function to process a work.
 *
 * CONTEXT:
 * spin_lock_irq(pool->lock) which is released and regrabbed.
 */
static void process_one_work(struct worker *worker, struct work_struct *work)
__releases(&pool->lock)
__acquires(&pool->lock)
{
	struct pool_workqueue *pwq = get_work_pwq(work);
	struct worker_pool *pool = worker->pool;
	bool cpu_intensive = pwq->wq->flags & WQ_CPU_INTENSIVE;
	int work_color;
	struct worker *collision;
#ifdef CONFIG_LOCKDEP
	/*
	 * It is permissible to free the struct work_struct from
	 * inside the function that is called from it, this we need to
	 * take into account for lockdep too.  To avoid bogus "held
	 * lock freed" warnings as well as problems when looking into
	 * work->lockdep_map, make a copy and use that here.
	 */
	struct lockdep_map lockdep_map;

	lockdep_copy_map(&lockdep_map, &work->lockdep_map);
#endif
	/* ensure we're on the correct CPU */
	WARN_ON_ONCE(!(pool->flags & POOL_DISASSOCIATED) &&
		     raw_smp_processor_id() != pool->cpu);

	/*
	 * A single work shouldn't be executed concurrently by
	 * multiple workers on a single cpu.  Check whether anyone is
	 * already processing the work.  If so, defer the work to the
	 * currently executing one.
	 */
        // 如果 work 已经在 worker_pool 的其他 worker 上执行，
	// 将 work 放入对应 worker 的 scheduled 队列中延后执行
	collision = find_worker_executing_work(pool, work);
	if (unlikely(collision)) {
		move_linked_works(work, &collision->scheduled, NULL);
		return;
	}

	/* claim and dequeue */
        // 将 worker 加入 busy 队列 pool->busy_hash
	debug_work_deactivate(work);
	hash_add(pool->busy_hash, &worker->hentry, (unsigned long)work);
	worker->current_work = work;
	worker->current_func = work->func;
	worker->current_pwq = pwq;
	work_color = get_work_color(work);

	list_del_init(&work->entry);
```

## worker_set_flags - WQ_CPU_INTENSIVE

这里worker_pool的调度思想是: 如果有 work 需要处理，保持一个 running 状态的 worker 处理，不多也不少。

但是这里有一个问题如果 work 是 CPU 密集型的，它虽然也没有进入 suspend 状态，但是会长时间的占用 CPU，
让后续的 work 阻塞太长时间。 为了解决这个问题，CMWQ 设计了 WQ_CPU_INTENSIVE，如果一个 wq 声明
自己是 CPU_INTENSIVE，则让当前 worker 脱离动态调度，像是进入了 suspend 状态，那么 CMWQ 会创建
新的 worker，后续的 work
会得到执行。

```
	/*
	 * CPU intensive works don't participate in concurrency management.
	 * They're the scheduler's responsibility.  This takes @worker out
	 * of concurrency management and the next code block will chain
	 * execution of the pending work items.
	 */
        // 如果 work 所在的 wq 是 cpu 密集型的 WQ_CPU_INTENSIVE
	// 则当前 work 的执行脱离 worker_pool 的动态调度，成为一个独立的线程
	if (unlikely(cpu_intensive))
		worker_set_flags(worker, WORKER_CPU_INTENSIVE);
```

## wake_up_worker

接上一步，判断是否需要唤醒新的 worker 来处理 work

```
	/*
	 * Wake up another worker if necessary.  The condition is always
	 * false for normal per-cpu workers since nr_running would always
	 * be >= 1 at this point.  This is used to chain execution of the
	 * pending work items for WORKER_NOT_RUNNING workers such as the
	 * UNBOUND and CPU_INTENSIVE ones.
	 */
        // 在 UNBOUND 或者 CPU_INTENSIVE work 中判断是否需要唤醒 idle worker
	// 普通 work 不会执行这个操作
	if (need_more_worker(pool))
		wake_up_worker(pool);
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/wake_up_worker.md

## set_work_pool_and_clear_pending

```
	/*
	 * Record the last pool and clear PENDING which should be the last
	 * update to @work.  Also, do this inside @pool->lock so that
	 * PENDING and queued state changes happen together while IRQ is
	 * disabled.
	 */
	set_work_pool_and_clear_pending(work, pool->id);

	spin_unlock_irq(&pool->lock);

	lock_map_acquire_read(&pwq->wq->lockdep_map);
	lock_map_acquire(&lockdep_map);
	trace_workqueue_execute_start(work);
```

## worker->current_func

执行 work 函数.

```
	worker->current_func(work);
	/*
	 * While we must be careful to not use "work" after this, the trace
	 * point will only record its address.
	 */
	trace_workqueue_execute_end(work);
	lock_map_release(&lockdep_map);
	lock_map_release(&pwq->wq->lockdep_map);

	if (unlikely(in_atomic() || lockdep_depth(current) > 0)) {
		pr_err("BUG: workqueue leaked lock or atomic: %s/0x%08x/%d\n"
		       "     last function: %pf\n",
		       current->comm, preempt_count(), task_pid_nr(current),
		       worker->current_func);
		debug_show_held_locks(current);
		dump_stack();
	}

	/*
	 * The following prevents a kworker from hogging CPU on !PREEMPT
	 * kernels, where a requeueing work item waiting for something to
	 * happen could deadlock with stop_machine as such work item could
	 * indefinitely requeue itself while all other CPUs are trapped in
	 * stop_machine. At the same time, report a quiescent RCU state so
	 * the same condition doesn't freeze RCU.
	 */
	cond_resched_rcu_qs();

	spin_lock_irq(&pool->lock);
```

## worker_clr_flags -> WORKER_CPU_INTENSIVE

```
	/* clear cpu intensive status */
	if (unlikely(cpu_intensive))
		worker_clr_flags(worker, WORKER_CPU_INTENSIVE);

	/* we're done with it, release */
	hash_del(&worker->hentry);
	worker->current_work = NULL;
	worker->current_func = NULL;
	worker->current_pwq = NULL;
	worker->desc_valid = false;
	pwq_dec_nr_in_flight(pwq, work_color);
}
```