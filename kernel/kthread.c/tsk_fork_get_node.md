tsk_fork_get_node
========================================

path: kernel/kthread.c
```
/* called from do_fork() to get node information for about to be created task */
int tsk_fork_get_node(struct task_struct *tsk)
{
#ifdef CONFIG_NUMA
    if (tsk == kthreadd_task)
        return tsk->pref_node_fork;
#endif
    return NUMA_NO_NODE;
}
```
