# apply_wqattrs_prepare

```
/* allocate the attrs and pwqs for later installation */
static struct apply_wqattrs_ctx *
apply_wqattrs_prepare(struct workqueue_struct *wq,
		      const struct workqueue_attrs *attrs)
{
	struct apply_wqattrs_ctx *ctx;
	struct workqueue_attrs *new_attrs, *tmp_attrs;
	int node;

	lockdep_assert_held(&wq_pool_mutex);

	ctx = kzalloc(sizeof(*ctx) + nr_node_ids * sizeof(ctx->pwq_tbl[0]),
		      GFP_KERNEL);

	new_attrs = alloc_workqueue_attrs(GFP_KERNEL);
	tmp_attrs = alloc_workqueue_attrs(GFP_KERNEL);
	if (!ctx || !new_attrs || !tmp_attrs)
		goto out_free;

	/*
	 * Calculate the attrs of the default pwq.
	 * If the user configured cpumask doesn't overlap with the
	 * wq_unbound_cpumask, we fallback to the wq_unbound_cpumask.
	 */
	copy_workqueue_attrs(new_attrs, attrs);
	cpumask_and(new_attrs->cpumask, new_attrs->cpumask, wq_unbound_cpumask);
	if (unlikely(cpumask_empty(new_attrs->cpumask)))
		cpumask_copy(new_attrs->cpumask, wq_unbound_cpumask);

	/*
	 * We may create multiple pwqs with differing cpumasks.  Make a
	 * copy of @new_attrs which will be modified and used to obtain
	 * pools.
	 */
	copy_workqueue_attrs(tmp_attrs, new_attrs);
```

## alloc_unbound_pwq

根据的 ubound 的 ordered_wq_attrs/unbound_std_wq_attrs创建对应的 pool_workqueue 和 worker_pool,
其中 worker_pool 不是默认创建好的，是需要动态创建的，对应的 worker 内核进程也要重新创建
创建好的 pool_workqueue 赋值给 pwq_tbl[node]

```
	/*
	 * If something goes wrong during CPU up/down, we'll fall back to
	 * the default pwq covering whole @attrs->cpumask.  Always create
	 * it even if we don't use it immediately.
	 */
	ctx->dfl_pwq = alloc_unbound_pwq(wq, new_attrs);
	if (!ctx->dfl_pwq)
		goto out_free;

	for_each_node(node) {
		if (wq_calc_node_cpumask(new_attrs, node, -1, tmp_attrs->cpumask)) {
			ctx->pwq_tbl[node] = alloc_unbound_pwq(wq, tmp_attrs);
			if (!ctx->pwq_tbl[node])
				goto out_free;
		} else {
			ctx->dfl_pwq->refcnt++;
			ctx->pwq_tbl[node] = ctx->dfl_pwq;
		}
	}

	/* save the user configured attrs and sanitize it. */
	copy_workqueue_attrs(new_attrs, attrs);
	cpumask_and(new_attrs->cpumask, new_attrs->cpumask, cpu_possible_mask);
	ctx->attrs = new_attrs;

	ctx->wq = wq;
	free_workqueue_attrs(tmp_attrs);
	return ctx;

out_free:
	free_workqueue_attrs(tmp_attrs);
	free_workqueue_attrs(new_attrs);
	apply_wqattrs_cleanup(ctx);
	return NULL;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/alloc_unbound_pwq.md
