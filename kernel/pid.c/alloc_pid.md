alloc_pid
========================================

在建立一个新进程时，进程可能在多个命名空间中是可见的。对每个这样的命名空间，都需要生成一个局部
PID。这是在alloc_pid中处理的.

Arguments
----------------------------------------

path: kernel/pid.c
```
struct pid *alloc_pid(struct pid_namespace *ns)
{
    struct pid *pid;
    enum pid_type type;
    int i, nr;
    struct pid_namespace *tmp;
    struct upid *upid;
```

Alloc
----------------------------------------

```
    pid = kmem_cache_alloc(ns->pid_cachep, GFP_KERNEL);
    if (!pid)
        goto out;

    tmp = ns;
    for (i = ns->level; i >= 0; i--) {
        // 为跟踪已经分配和仍然可用的PID，内核使用一个大的位图，其中每个PID由一个比特标识。
        // PID的值可通过对应比特在位图中的位置计算而来。因此，分配一个空闲的PID，本质上就
        // 等同于寻找位图中第一个值为0的比特，接下来将该比特设置为1。反之，释放一个PID可
        // 通过将对应的比特从1切换为0来实现。
        nr = alloc_pidmap(tmp);
        if (nr < 0)
            goto out_free;

        pid->numbers[i].nr = nr;
        pid->numbers[i].ns = tmp;
        tmp = tmp->parent;
    }

    get_pid_ns(ns);
    pid->level = ns->level;
    atomic_set(&pid->count, 1);
    for (type = 0; type < PIDTYPE_MAX; ++type)
        INIT_HLIST_HEAD(&pid->tasks[type]);

    upid = pid->numbers + ns->level;
    spin_lock_irq(&pidmap_lock);
    // 起始于建立进程的命名空间，一直到初始的全局命名空间，内核会为此间的每个命名空间分别
    // 创建一个局部PID。包含在struct pid中的所有upid都用重新生成的PID更新其数据。每个upid
    // 实例都必须置于PID散列表中：
    for ( ; upid >= pid->numbers; --upid)
        hlist_add_head_rcu(&upid->pid_chain,
                &pid_hash[pid_hashfn(upid->nr, upid->ns)]);
    spin_unlock_irq(&pidmap_lock);

out:
    return pid;

out_free:
    while (++i <= ns->level)
        free_pidmap(pid->numbers + i);

    kmem_cache_free(ns->pid_cachep, pid);
    pid = NULL;
    goto out;
}
```