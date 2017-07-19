# create_worker

```
/**
 * create_worker - create a new workqueue worker
 * @pool: pool the new worker will belong to
 *
 * Create and start a new worker which is attached to @pool.
 *
 * CONTEXT:
 * Might sleep.  Does GFP_KERNEL allocations.
 *
 * Return:
 * Pointer to the newly created worker.
 */
static struct worker *create_worker(struct worker_pool *pool)
{
	struct worker *worker = NULL;
	int id = -1;
	char id_buf[16];

	/* ID is needed to determine kthread name */
	id = ida_simple_get(&pool->worker_ida, 0, 0, GFP_KERNEL);
	if (id < 0)
		goto fail;

	worker = alloc_worker(pool->node);
	if (!worker)
		goto fail;

	worker->pool = pool;
	worker->id = id;

	if (pool->cpu >= 0)
		snprintf(id_buf, sizeof(id_buf), "%d:%d%s", pool->cpu, id,
			 pool->attrs->nice < 0  ? "H" : "");
	else
		snprintf(id_buf, sizeof(id_buf), "u%d:%d", pool->id, id);
	worker->task = kthread_create_on_node(worker_thread, worker, pool->node,
					      "kworker/%s", id_buf);
	if (IS_ERR(worker->task))
		goto fail;

	set_user_nice(worker->task, pool->attrs->nice);
	kthread_bind_mask(worker->task, pool->attrs->cpumask);

	/* successful, attach the worker to the pool */
	worker_attach_to_pool(worker, pool);

	/* start the newly created worker */
	spin_lock_irq(&pool->lock);
	worker->pool->nr_workers++;
	worker_enter_idle(worker);
	wake_up_process(worker->task);
	spin_unlock_irq(&pool->lock);

	return worker;

fail:
	if (id >= 0)
		ida_simple_remove(&pool->worker_ida, id);
	kfree(worker);
	return NULL;
}
```

### kthread_create_on_node

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/kthread.c/kthread_create_on_node.md

### worker_thread

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/worker_thread.md
