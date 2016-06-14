find_task_by_pid_ns
========================================

path: kernel/pid.c
```
/*
 * Must be called under rcu_read_lock().
 */
struct task_struct *find_task_by_pid_ns(pid_t nr, struct pid_namespace *ns)
{
    RCU_LOCKDEP_WARN(!rcu_read_lock_held(),
             "find_task_by_pid_ns() needs rcu_read_lock() protection");
    return pid_task(find_pid_ns(nr, ns), PIDTYPE_PID);
}
```

pid_task
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/pid.c/pid_task.md