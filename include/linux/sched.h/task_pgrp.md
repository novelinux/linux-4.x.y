task_pgrp
========================================

找出进程组ID则需要使用PIDTYPE_PGID作为数组索引，但该ID仍然需要从线程组组长的task_struct实例获取.

path: include/linux/sched.h
```
/*
 * Without tasklist or rcu lock it is not safe to dereference
 * the result of task_pgrp/task_session even if task == current,
 * we can race with another thread doing sys_setsid/sys_setpgid.
 */
static inline struct pid *task_pgrp(struct task_struct *task)
{
    return task->group_leader->pids[PIDTYPE_PGID].pid;
}
```