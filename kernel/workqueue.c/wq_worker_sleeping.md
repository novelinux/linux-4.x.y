# wq_worker_sleeping

```
/**
 * wq_worker_sleeping - a worker is going to sleep
 * @task: task going to sleep
 *
 * This function is called during schedule() when a busy worker is
 * going to sleep.  Worker on the same cpu can be woken up by
 * returning pointer to its task.
 *
 * CONTEXT:
 * spin_lock_irq(rq->lock)
 *
 * Return:
 * Worker task on @cpu to wake up, %NULL if none.
 */
struct task_struct *wq_worker_sleeping(struct task_struct *task)
{
	struct worker *worker = kthread_data(task), *to_wakeup = NULL;
	struct worker_pool *pool;

	/*
	 * Rescuers, which may not have all the fields set up like normal
	 * workers, also reach here, let's not access anything before
	 * checking NOT_RUNNING.
	 */
	if (worker->flags & WORKER_NOT_RUNNING)
		return NULL;

	pool = worker->pool;

	/* this can only happen on the local cpu */
	if (WARN_ON_ONCE(pool->cpu != raw_smp_processor_id()))
		return NULL;

	/*
	 * The counterpart of the following dec_and_test, implied mb,
	 * worklist not empty test sequence is in insert_work().
	 * Please read comment there.
	 *
	 * NOT_RUNNING is clear.  This means that we're bound to and
	 * running on the local cpu w/ rq lock held and preemption
	 * disabled, which in turn means that none else could be
	 * manipulating idle_list, so dereferencing idle_list without pool
	 * lock is safe.
	 */
	if (atomic_dec_and_test(&pool->nr_running) &&
	    !list_empty(&pool->worklist))
		to_wakeup = first_idle_worker(pool);
	return to_wakeup ? to_wakeup->task : NULL;
}
```