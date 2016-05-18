__perform_reclaim
========================================

Arguments
----------------------------------------

path: mm/page_alloc.c
```
/* Perform direct synchronous page reclaim */
static int
__perform_reclaim(gfp_t gfp_mask, unsigned int order,
                    const struct alloc_context *ac)
{
    struct reclaim_state reclaim_state;
    int progress;
```

cond_resched
----------------------------------------

```
    cond_resched();
```

内核通过cond_resched提供了重调度的时机,这防止了花费过多时间搜索内存,以致于使其他进程处于饥饿状态.

try_to_free_pages
----------------------------------------

分页机制提供了一个目前尚未使用的选项，将很少使用的页换出到块介质，以便在物理内存中产生更多空间。
但该选项非常耗时，还可能导致进程睡眠状态。try_to_free_pages是相应的辅助函数，用于查找当前不
急需的页，以便换出。在该分配任务设置了PF_MEMALLOC标志之后，会调用该函数，用于向其余的内核代码
表明所有后续的内存分配都需要这样的搜索。

该调用被设置/清除PF_MEMALLOC标志的代码间隔起来。try_to_free_pages自身可能也需要分配新的内存。
由于为获得新内存还需要额外分配一点内存（相当矛盾的情形），该进程当然应该在内存管理方面享有
最高优先级，上述标志的设置即达到了这一目的。回忆前几行代码，在设置了PF_MEMALLOC标志时，
内存分配非常积极。此外，设置该标志确保了try_to_free_pages不会递归调用，因为如果此前设置了
PF_MEMALLOC，那么__alloc_pages肯定已经返回。

该函数选择最近不十分活跃的页，将其写到交换区，在物理内存中腾出空间，即可。try_to_free_pages
会返回增加的空闲页数目。try_to_free_pages只作用于包含预期内存域的结点。忽略所有其他结点。

如果需要分配多页，那么per-CPU缓存中的页也会拿回到伙伴系统.

```
    /* We now go into synchronous reclaim */
    cpuset_memory_pressure_bump();
    current->flags |= PF_MEMALLOC;
    lockdep_set_current_reclaim_state(gfp_mask);
    reclaim_state.reclaimed_slab = 0;
    current->reclaim_state = &reclaim_state;

    progress = try_to_free_pages(ac->zonelist, order, gfp_mask,
                                ac->nodemask);

    current->reclaim_state = NULL;
    lockdep_clear_current_reclaim_state();
    current->flags &= ~PF_MEMALLOC;

    cond_resched();

    return progress;
}
```