# wake_up_workder

```
/**
 * wake_up_worker - wake up an idle worker
 * @pool: worker pool to wake worker from
 *
 * Wake up the first idle worker of @pool.
 *
 * CONTEXT:
 * spin_lock_irq(pool->lock).
 */
static void wake_up_worker(struct worker_pool *pool)
{
	struct worker *worker = first_idle_worker(pool);

	if (likely(worker))
		wake_up_process(worker->task);
}
```

## wake_up_process

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/core.c/wake_up_process.md
