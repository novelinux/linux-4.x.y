# get_unbound_pool

```
/**
 * get_unbound_pool - get a worker_pool with the specified attributes
 * @attrs: the attributes of the worker_pool to get
 *
 * Obtain a worker_pool which has the same attributes as @attrs, bump the
 * reference count and return it.  If there already is a matching
 * worker_pool, it will be used; otherwise, this function attempts to
 * create a new one.
 *
 * Should be called with wq_pool_mutex held.
 *
 * Return: On success, a worker_pool with the same attributes as @attrs.
 * On failure, %NULL.
 */
static struct worker_pool *get_unbound_pool(const struct workqueue_attrs *attrs)
{
	u32 hash = wqattrs_hash(attrs);
	struct worker_pool *pool;
	int node;
	int target_node = NUMA_NO_NODE;

	lockdep_assert_held(&wq_pool_mutex);

	/* do we already have a matching pool? */
	hash_for_each_possible(unbound_pool_hash, pool, hash_node, hash) {
		if (wqattrs_equal(pool->attrs, attrs)) {
			pool->refcnt++;
			return pool;
		}
	}

	/* if cpumask is contained inside a NUMA node, we belong to that node */
	if (wq_numa_enabled) {
		for_each_node(node) {
			if (cpumask_subset(attrs->cpumask,
					   wq_numa_possible_cpumask[node])) {
				target_node = node;
				break;
			}
		}
	}

	/* nope, create a new one */
	pool = kzalloc_node(sizeof(*pool), GFP_KERNEL, target_node);
	if (!pool || init_worker_pool(pool) < 0)
		goto fail;

	lockdep_set_subclass(&pool->lock, 1);	/* see put_pwq() */
	copy_workqueue_attrs(pool->attrs, attrs);
	pool->node = target_node;

	/*
	 * no_numa isn't a worker_pool attribute, always clear it.  See
	 * 'struct workqueue_attrs' comments for detail.
	 */
	pool->attrs->no_numa = false;

	if (worker_pool_assign_id(pool) < 0)
		goto fail;

	/* create and start the initial worker */
	if (wq_online && !create_worker(pool))
		goto fail;

	/* install */
	hash_add(unbound_pool_hash, &pool->hash_node, hash);

	return pool;
fail:
	if (pool)
		put_unbound_pool(pool);
	return NULL;
}
```