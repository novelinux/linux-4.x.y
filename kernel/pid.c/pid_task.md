pid_task
========================================

pid_task函数取出pid->tasks[type]散列表中的第一个task_struct实例。

path: kernel/pid.c
```
struct task_struct *pid_task(struct pid *pid, enum pid_type type)
{
    struct task_struct *result = NULL;
    if (pid) {
        struct hlist_node *first;
        first = rcu_dereference_check(hlist_first_rcu(&pid->tasks[type]),
                          lockdep_tasklist_lock_is_held());
        if (first)
            result = hlist_entry(first, struct task_struct, pids[(type)].node);
    }
    return result;
}
```