# ttwu_do_activate

```
static void
ttwu_do_activate(struct rq *rq, struct task_struct *p, int wake_flags,
		 struct rq_flags *rf)
{
	int en_flags = ENQUEUE_WAKEUP | ENQUEUE_NOCLOCK;

	lockdep_assert_held(&rq->lock);

#ifdef CONFIG_SMP
	if (p->sched_contributes_to_load)
		rq->nr_uninterruptible--;

	if (wake_flags & WF_MIGRATED)
		en_flags |= ENQUEUE_MIGRATED;
#endif
```

## ttwu_activate

```
	ttwu_activate(rq, p, en_flags);
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/sched/core.c/ttwu_activate.md

## ttwu_do_wakeup

```
	ttwu_do_wakeup(rq, p, wake_flags, rf);
}
```