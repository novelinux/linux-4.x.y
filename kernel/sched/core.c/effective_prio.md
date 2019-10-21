### effective_prio

这里首先计算了普通优先级，并保存在normal_priority。这个副效应使得能够用一个函数调用设置两个优先级（prio和normal_prio）。另一个辅助函数rt_prio，会检测普通优先级是否在实时范围中，即是否小于RT_RT_PRIO。请注意，该检测与调度类无关，它只涉及优先级的数值。

现在假定我们在处理普通进程，不涉及实时调度。在这种情况下，normal_prio只是返回静态优先级。结果很简单：所有3个优级都是同一个值，即静态优先级！

普通优先级需要根据普通进程和实时进程进行不同的计算。__normal_prio的计算只适用于普通进程。而实时进程的普通优先级计算，则需要根据其rt_priority设置。由于更高的rt_priority值表示更高的实时优先级，内核内部优先级的表示刚好相反，越低的值表示的优先级越高。因此，实时进程在内核内部的优先级数值，正确的算法是MAX_RT_PRIO - 1 - p->rt_priority。这一次请注意，与effective_prio相比，实时进程的检测不再基于优先级数值，而是通过task_struct中设置的调度策略来检测。__normal_priority做什么呢？该函数实际上很简单，它只是返回静态优先级：

** [Effective Priority](./prio_policy.jpeg)

```
/*
 * __normal_prio - return the priority that is based on the static prio
 */
static inline int __normal_prio(struct task_struct *p)
{
	return p->static_prio;
}

/*
 * Calculate the expected normal priority: i.e. priority
 * without taking RT-inheritance into account. Might be
 * boosted by interactivity modifiers. Changes upon fork,
 * setprio syscalls, and whenever the interactivity
 * estimator recalculates.
 */
static inline int normal_prio(struct task_struct *p)
{
	int prio;

	if (task_has_dl_policy(p))
		prio = MAX_DL_PRIO-1;
	else if (task_has_rt_policy(p))
		prio = MAX_RT_PRIO-1 - p->rt_priority;
	else
		prio = __normal_prio(p);
	return prio;
}

/*
 * Calculate the current priority, i.e. the priority
 * taken into account by the scheduler. This value might
 * be boosted by RT tasks, or might be boosted by
 * interactivity modifiers. Will be RT if the task got
 * RT-boosted. If not then it returns p->normal_prio.
 */
static int effective_prio(struct task_struct *p)
{
	p->normal_prio = normal_prio(p);
	/*
	 * If we are RT tasks or we were boosted to RT priority,
	 * keep the priority unchanged. Otherwise, update priority
	 * to the normal priority:
	 */
	if (!rt_prio(p->prio))
		return p->normal_prio;
	return p->prio;
}

```

在新建进程用wake_up_new_task唤醒时，或使用nice系统调用改变静态优先级时，则用上文给出的方法设置p->prio。请注意，在进程分支出子进程时，子进程的静态优先级继承自父进程。子进程的动态优先级，即task_struct->prio，则设置为父进程的普通优先级。这确保了实时互斥量引起的优先级提高不会传递到子进程。