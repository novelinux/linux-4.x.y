# apply_workqueue_attrs

```
/**
 * apply_workqueue_attrs - apply new workqueue_attrs to an unbound workqueue
 * @wq: the target workqueue
 * @attrs: the workqueue_attrs to apply, allocated with alloc_workqueue_attrs()
 *
 * Apply @attrs to an unbound workqueue @wq.  Unless disabled, on NUMA
 * machines, this function maps a separate pwq to each NUMA node with
 * possibles CPUs in @attrs->cpumask so that work items are affine to the
 * NUMA node it was issued on.  Older pwqs are released as in-flight work
 * items finish.  Note that a work item which repeatedly requeues itself
 * back-to-back will stay on its current pwq.
 *
 * Performs GFP_KERNEL allocations.
 *
 * Return: 0 on success and -errno on failure.
 */
int apply_workqueue_attrs(struct workqueue_struct *wq,
			  const struct workqueue_attrs *attrs)
{
	int ret;

	apply_wqattrs_lock();
	ret = apply_workqueue_attrs_locked(wq, attrs);
	apply_wqattrs_unlock();

	return ret;
}
```

## apply_workqueue_attrs_locked

```
static int apply_workqueue_attrs_locked(struct workqueue_struct *wq,
					const struct workqueue_attrs *attrs)
{
	struct apply_wqattrs_ctx *ctx;

	/* only unbound workqueues can change attributes */
	if (WARN_ON(!(wq->flags & WQ_UNBOUND)))
		return -EINVAL;

	/* creating multiple pwqs breaks ordering guarantee */
	if (WARN_ON((wq->flags & __WQ_ORDERED) && !list_empty(&wq->pwqs)))
		return -EINVAL;
```

### apply_wqattrs_prepare

```
	ctx = apply_wqattrs_prepare(wq, attrs);
	if (!ctx)
		return -ENOMEM;
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/apply_wqattrs_prepare.md

### apply_wqattrs_commit

```
	/* the ctx has been prepared successfully, let's commit it */
	apply_wqattrs_commit(ctx);
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/apply_wqattrs_commit.md

### apply_wqattrs_cleanup

```
	apply_wqattrs_cleanup(ctx);

	return 0;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/apply_wqattrs_cleanup.md
