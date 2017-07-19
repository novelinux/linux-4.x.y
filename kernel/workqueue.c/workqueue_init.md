# workqueue_init

```
/**
 * workqueue_init - bring workqueue subsystem fully online
 *
 * This is the latter half of two-staged workqueue subsystem initialization
 * and invoked as soon as kthreads can be created and scheduled.
 * Workqueues have been created and work items queued on them, but there
 * are no kworkers executing the work items yet.  Populate the worker pools
 * with the initial workers and enable future kworker creations.
 */
int __init workqueue_init(void)
{
	struct workqueue_struct *wq;
	struct worker_pool *pool;
	int cpu, bkt;

	/*
	 * It'd be simpler to initialize NUMA in workqueue_init_early() but
	 * CPU to node mapping may not be available that early on some
	 * archs such as power and arm64.  As per-cpu pools created
	 * previously could be missing node hint and unbound pools NUMA
	 * affinity, fix them up.
	 */
	wq_numa_init();

	mutex_lock(&wq_pool_mutex);

	for_each_possible_cpu(cpu) {
		for_each_cpu_worker_pool(pool, cpu) {
			pool->node = cpu_to_node(cpu);
		}
	}

	list_for_each_entry(wq, &workqueues, list)
		wq_update_unbound_numa(wq, smp_processor_id(), true);

	mutex_unlock(&wq_pool_mutex);
```

## create_worker

给每个worker_pool创建第一个worker

```
	/* create the initial workers */
	for_each_online_cpu(cpu) {
		for_each_cpu_worker_pool(pool, cpu) {
			pool->flags &= ~POOL_DISASSOCIATED;
			BUG_ON(!create_worker(pool));
		}
	}

	hash_for_each(unbound_pool_hash, bkt, pool, hash_node)
		BUG_ON(!create_worker(pool));

	wq_online = true;
	wq_watchdog_init();

	return 0;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/create_worker.md
