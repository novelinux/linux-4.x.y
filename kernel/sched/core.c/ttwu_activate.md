# ttwu_activate

```
static inline void ttwu_activate(struct rq *rq, struct task_struct *p, int en_flags)
{
	activate_task(rq, p, en_flags);
	p->on_rq = TASK_ON_RQ_QUEUED;

	/* If a worker is waking up, notify the workqueue: */
	if (p->flags & PF_WQ_WORKER)
		wq_worker_waking_up(p, cpu_of(rq));
}
```

## wq_worker_waking_up

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/wq_worker_waking_up.md
