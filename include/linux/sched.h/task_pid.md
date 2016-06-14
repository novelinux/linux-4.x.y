task_pid
========================================

获得与task_struct关联的pid实例.

path: include/linux/sched.h
```
static inline struct pid *task_pid(struct task_struct *task)
{
    return task->pids[PIDTYPE_PID].pid;
}
```