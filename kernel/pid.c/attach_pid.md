attach_pid
========================================

path: kernel/pid.c
```
/*
 * attach_pid() must be called with the tasklist_lock write-held.
 */
void attach_pid(struct task_struct *task, enum pid_type type,
        struct pid *pid)
{
    struct pid_link *link;

    // 这里建立了双向连接：task_struct可以通过task_struct->pids[type]->pid访问pid实例。
    // 而从pid实例开始，可以遍历tasks[type]散列表找到task_struct。hlist_add_head_rcu
    // 是遍历散列表的标准函数，此外还确保了遵守RCU机制。因为，在其他内核组件并发地操作
    // 散列表时，可防止竞态条件（race condition）出现。
    link = &task->pids[type];
    link->pid = pid;
    hlist_add_head_rcu(&link->node, &pid->tasks[type]);
}
```