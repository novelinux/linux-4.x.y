# flush work

flush 某个 work，确保 work 执行完成。

怎么判断异步的 work 已经执行完成？这里面使用了一个技巧：在目标 work 的后面插入一个新的
work wq_barrier，如果 wq_barrier 执行完成，那么目标 work 肯定已经执行完成。

```
/**
 * flush_work - wait for a work to finish executing the last queueing instance
 * @work: the work to flush
 *
 * Wait until @work has finished execution.  @work is guaranteed to be idle
 * on return if it hasn't been requeued since flush started.
 *
 * Return:
 * %true if flush_work() waited for the work to finish execution,
 * %false if it was already idle.
 */
bool flush_work(struct work_struct *work)
{
	struct wq_barrier barr;

	if (WARN_ON(!wq_online))
		return false;

	lock_map_acquire(&work->lockdep_map);
	lock_map_release(&work->lockdep_map);
```

## start_flush_work

```
	if (start_flush_work(work, &barr)) {
		wait_for_completion(&barr.done);
		destroy_work_on_stack(&barr.work);
		return true;
	} else {
		return false;
	}
}
EXPORT_SYMBOL_GPL(flush_work);
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/start_flush_work.md
