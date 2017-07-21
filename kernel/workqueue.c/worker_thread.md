# worker_thread

```
/**
 * worker_thread - the worker thread function
 * @__worker: self
 *
 * The worker thread function.  All workers belong to a worker_pool -
 * either a per-cpu one or dynamic unbound one.  These workers process all
 * work items regardless of their specific target workqueue.  The only
 * exception is work items which belong to workqueues with a rescuer which
 * will be explained in rescuer_thread().
 *
 * Return: 0
 */
static int worker_thread(void *__worker)
{
	struct worker *worker = __worker;
	struct worker_pool *pool = worker->pool;

	/* tell the scheduler that this is a workqueue worker */
	worker->task->flags |= PF_WQ_WORKER;
woke_up:
	spin_lock_irq(&pool->lock);

	/* am I supposed to die? */
        // (1) 是否 die
	if (unlikely(worker->flags & WORKER_DIE)) {
		spin_unlock_irq(&pool->lock);
		WARN_ON_ONCE(!list_empty(&worker->entry));
		worker->task->flags &= ~PF_WQ_WORKER;

		set_task_comm(worker->task, "kworker/dying");
		ida_simple_remove(&pool->worker_ida, worker->id);
		worker_detach_from_pool(worker, pool);
		kfree(worker);
		return 0;
	}
        // (2) 脱离 idle 状态, 被唤醒之前 worker 都是 idle 状态
	worker_leave_idle(worker);
recheck:
        // (3) 如果需要本 worker 继续执行则继续，否则进入 idle 状态
	/* no more worker necessary? */
	if (!need_more_worker(pool))
		goto sleep;

        // (4) 如果 (pool->nr_idle == 0)，则启动创建更多的 worker
	// 说明 idle 队列中已经没有备用 worker 了，先创建 一些 worker 备用
	/* do we need to manage? */
	if (unlikely(!may_start_working(pool)) && manage_workers(worker))
		goto recheck;

	/*
	 * ->scheduled list can only be filled while a worker is
	 * preparing to process a work or actually processing it.
	 * Make sure nobody diddled with it while I was sleeping.
	 */
	WARN_ON_ONCE(!list_empty(&worker->scheduled));

	/*
	 * Finish PREP stage.  We're guaranteed to have at least one idle
	 * worker or that someone else has already assumed the manager
	 * role.  This is where @worker starts participating in concurrency
	 * management if applicable and concurrency management is restored
	 * after being rebound.  See rebind_workers() for details.
	 */
	worker_clr_flags(worker, WORKER_PREP | WORKER_REBOUND);
```

## process_one_work

如果 pool->worklist 不为空，从其中取出一个 work 进行处理

```
	do {
		struct work_struct *work =
			list_first_entry(&pool->worklist,
					 struct work_struct, entry);

		pool->watchdog_ts = jiffies;

		if (likely(!(*work_data_bits(work) & WORK_STRUCT_LINKED))) {
			/* optimization path, not strictly necessary */
			process_one_work(worker, work); // 执行正常的 work
			if (unlikely(!list_empty(&worker->scheduled)))
				process_scheduled_works(worker);
		} else {
                        // 执行系统特意 scheduled 给某个 worker 的 work
			// 普通的 work 是放在池子的公共 list 中的 pool->worklist
			// 只有一些特殊的 work 被特意派送给某个 worker 的 worker->scheduled
			// 包括：1.执行 flush_work 时插入的 barrier work；
			// 2.collision 时从其他 worker 推送到本 worker 的 work
			move_linked_works(work, &worker->scheduled, NULL);
			process_scheduled_works(worker);
		}

	} while (keep_working(pool));

	worker_set_flags(worker, WORKER_PREP);
sleep:
	/*
	 * pool->lock is held and there's no work to process and no need to
	 * manage, sleep.  Workers are woken up only while holding
	 * pool->lock or from local cpu, so setting the current state
	 * before releasing pool->lock is enough to prevent losing any
	 * event.
	 */
	worker_enter_idle(worker);
	__set_current_state(TASK_INTERRUPTIBLE);
	spin_unlock_irq(&pool->lock);
	schedule();
	goto woke_up;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/process_one_work.md