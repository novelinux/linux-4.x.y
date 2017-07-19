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
```

```
	/* ID is needed to determine kthread name */
	id = ida_simple_get(&pool->worker_ida, 0, 0, GFP_KERNEL);
	if (id < 0)
		goto fail;

	worker = alloc_worker(pool->node);
	if (!worker)
		goto fail;

	worker->pool = pool;
	worker->id = id;

	if (pool->cpu >= 0) // 给 normal worker_pool 的 worker 构造进程名
		snprintf(id_buf, sizeof(id_buf), "%d:%d%s", pool->cpu, id,
			 pool->attrs->nice < 0  ? "H" : "");
	else // 给 unbound worker_pool 的 worker 构造进程名
		snprintf(id_buf, sizeof(id_buf), "u%d:%d", pool->id, id);
```

## kthread_create_on_node

创建 worker 对应的内核进程

```
	worker->task = kthread_create_on_node(worker_thread, worker, pool->node,
					      "kworker/%s", id_buf);
	if (IS_ERR(worker->task))
		goto fail;

        // 设置内核进程对应的优先级 nice
	set_user_nice(worker->task, pool->attrs->nice);
	kthread_bind_mask(worker->task, pool->attrs->cpumask);
```

### kthread_create_on_node

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/kthread.c/kthread_create_on_node.md

### worker_thread

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/worker_thread.md

## worker_attach_to_pool

```
        // 将 worker 和 worker_pool 绑定
	/* successful, attach the worker to the pool */
	worker_attach_to_pool(worker, pool);

        // 将 worker 初始状态设置成 idle，
	// wake_up_process 以后，worker 自动 leave idle 状态
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

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/worker_attach_to_pool.md