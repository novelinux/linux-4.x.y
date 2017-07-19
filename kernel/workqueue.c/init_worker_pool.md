# init_worker_pool

```
/**
 * init_worker_pool - initialize a newly zalloc'd worker_pool
 * @pool: worker_pool to initialize
 *
 * Initialize a newly zalloc'd @pool.  It also allocates @pool->attrs.
 *
 * Return: 0 on success, -errno on failure.  Even on failure, all fields
 * inside @pool proper are initialized and put_unbound_pool() can be called
 * on @pool safely to release it.
 */
static int init_worker_pool(struct worker_pool *pool)
{
	spin_lock_init(&pool->lock);
	pool->id = -1;
	pool->cpu = -1;
	pool->node = NUMA_NO_NODE;
	pool->flags |= POOL_DISASSOCIATED;
	pool->watchdog_ts = jiffies;
        //worker_pool 的 work list，各个 workqueue 把 work 挂载到这个链表上，
	//让 worker_pool 对应的多个 worker 来执行
	INIT_LIST_HEAD(&pool->worklist);
        // worker_pool 的 idle worker list，worker 没有活干时，不会马上销毁，先进入 idle 状态备选
	INIT_LIST_HEAD(&pool->idle_list);
        //worker_pool 的 busy worker list，worker 正在干活，在执行 work
	hash_init(pool->busy_hash);

        // 检查 idle 状态 worker 是否需要 destroy 的 timer
	setup_deferrable_timer(&pool->idle_timer, idle_worker_timeout,
			       (unsigned long)pool);
        // 在 worker_pool 创建新的 worker 时，检查是否超时的 timer
	setup_timer(&pool->mayday_timer, pool_mayday_timeout,
		    (unsigned long)pool);

	mutex_init(&pool->manager_arb);
	mutex_init(&pool->attach_mutex);
	INIT_LIST_HEAD(&pool->workers);

	ida_init(&pool->worker_ida);
	INIT_HLIST_NODE(&pool->hash_node);
	pool->refcnt = 1;

	/* shouldn't fail above this point */
	pool->attrs = alloc_workqueue_attrs(GFP_KERNEL);
	if (!pool->attrs)
		return -ENOMEM;
	return 0;
}
```