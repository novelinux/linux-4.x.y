# alloc_and_link_pwqs

```
static int alloc_and_link_pwqs(struct workqueue_struct *wq)
{
	bool highpri = wq->flags & WQ_HIGHPRI;
	int cpu, ret;
```

## normal workqueue

normal workqueue, pool_workqueue 链接 workqueue 和 worker_pool 的过程

```
	if (!(wq->flags & WQ_UNBOUND)) {
		wq->cpu_pwqs = alloc_percpu(struct pool_workqueue);
		if (!wq->cpu_pwqs)
			return -ENOMEM;

		for_each_possible_cpu(cpu) {
			struct pool_workqueue *pwq =
				per_cpu_ptr(wq->cpu_pwqs, cpu);
			struct worker_pool *cpu_pools =
				per_cpu(cpu_worker_pools, cpu);

			init_pwq(pwq, wq, &cpu_pools[highpri]);

			mutex_lock(&wq->mutex);
			link_pwq(pwq);
			mutex_unlock(&wq->mutex);
		}
		return 0;
```

### init_pwq

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/init_pwq.md

## unbound workqueue

```
	} else if (wq->flags & __WQ_ORDERED) { // ordered_wq
		ret = apply_workqueue_attrs(wq, ordered_wq_attrs[highpri]);
		/* there should only be single pwq for ordering guarantee */
		WARN(!ret && (wq->pwqs.next != &wq->dfl_pwq->pwqs_node ||
			      wq->pwqs.prev != &wq->dfl_pwq->pwqs_node),
		     "ordering guarantee broken for workqueue %s\n", wq->name);
		return ret;
	} else {  // std_wq
		return apply_workqueue_attrs(wq, unbound_std_wq_attrs[highpri]);
	}
}
```

### apply_workqueue_attrs

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/apply_workqueue_attrs.md