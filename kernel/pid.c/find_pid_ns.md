find_pid_ns
========================================

给出进程的局部数字PID和关联的命名空间(这是PID的用户空间表示),为确定pid实例(这是PID的内核表示)，
内核必须采用标准的散列方案。

首先，根据PID和命名空间指针计算在pid_hash数组中的索引，然后遍历散列表直至找到所要的元素。
这是通过辅助函数find_pid_ns处理的：

path: kernel/pid.c
```
struct pid *find_pid_ns(int nr, struct pid_namespace *ns)
{
    struct upid *pnr;

    hlist_for_each_entry_rcu(pnr,
            &pid_hash[pid_hashfn(nr, ns)], pid_chain)
        if (pnr->nr == nr && pnr->ns == ns)
            return container_of(pnr, struct pid,
                    numbers[ns->level]);

    return NULL;
}
EXPORT_SYMBOL_GPL(find_pid_ns);
```