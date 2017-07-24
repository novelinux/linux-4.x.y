# wq_worker_waking_up

```
/**
 * wq_worker_waking_up - a worker is waking up
 * @task: task waking up
 * @cpu: CPU @task is waking up to
 *
 * This function is called during try_to_wake_up() when a worker is
 * being awoken.
 *
 * CONTEXT:
 * spin_lock_irq(rq->lock)
 */
void wq_worker_waking_up(struct task_struct *task, int cpu)
{
	struct worker *worker = kthread_data(task);

	if (!(worker->flags & WORKER_NOT_RUNNING)) {
		WARN_ON_ONCE(worker->pool->cpu != cpu);
		atomic_inc(&worker->pool->nr_running);
	}
}
```