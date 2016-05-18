__alloc_pages_slowpath
========================================

Arguments
----------------------------------------

path: mm/page_alloc.c
```
static inline struct page *
__alloc_pages_slowpath(gfp_t gfp_mask, unsigned int order,
                        struct alloc_context *ac)
{
```

Check
----------------------------------------

```
    const gfp_t wait = gfp_mask & __GFP_WAIT;
    struct page *page = NULL;
    int alloc_flags;
    unsigned long pages_reclaimed = 0;
    unsigned long did_some_progress;
    enum migrate_mode migration_mode = MIGRATE_ASYNC;
    bool deferred_compaction = false;
    int contended_compaction = COMPACT_CONTENDED_NONE;

    /*
     * In the slowpath, we sanity check order to avoid ever trying to
     * reclaim >= MAX_ORDER areas which will never succeed. Callers may
     * be using allocators in order of preference for an area that is
     * too large.
     */
    if (order >= MAX_ORDER) {
        WARN_ON_ONCE(!(gfp_mask & __GFP_NOWARN));
        return NULL;
    }

    /*
     * If this allocation cannot block and it is for a specific node, then
     * fail early.  There's no need to wakeup kswapd or retry for a
     * speculative node-specific allocation.
     */
    if (IS_ENABLED(CONFIG_NUMA) && (gfp_mask & __GFP_THISNODE) && !wait)
        goto nopage;
```

retry
----------------------------------------

### wake_all_kswapds

```
retry:
    if (!(gfp_mask & __GFP_NO_KSWAPD))
        wake_all_kswapds(order, ac);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/wake_all_kswapds.md

### gfp_to_alloc_flags

```
    /*
     * OK, we're below the kswapd watermark and have kicked background
     * reclaim. Now things get more complex, so set up alloc_flags according
     * to how we want to proceed.
     */
    alloc_flags = gfp_to_alloc_flags(gfp_mask);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/gfp_to_alloc_flags.md

### get_page_from_freelist

在交换守护进程唤醒后，内核开始新的尝试，在内存域之一查找适当的内存块。这一次进行的搜索更为积极，
对分配标志进行了调整，修改为一些在当前特定情况下更有可能分配成功的标志。同时，将水印降低到最小值。
对实时进程和指定了__GFP_WAIT标志因而不能睡眠的调用。然后用修改的标志集，再一次调用
get_page_from_freelist，试图获得所需的页。

```
    /*
     * Find the true preferred zone if the allocation is unconstrained by
     * cpusets.
     */
    if (!(alloc_flags & ALLOC_CPUSET) && !ac->nodemask) {
        struct zoneref *preferred_zoneref;
        preferred_zoneref = first_zones_zonelist(ac->zonelist,
                ac->high_zoneidx, NULL, &ac->preferred_zone);
        ac->classzone_idx = zonelist_zone_idx(preferred_zoneref);
    }

    /* This is the last chance, in general, before the goto nopage. */
    page = get_page_from_freelist(gfp_mask, order,
                alloc_flags & ~ALLOC_NO_WATERMARKS, ac);
    if (page)
        goto got_pg;
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/get_page_from_freelist.md

如果再次失败，内核会借助于更强有力的措施：

### __alloc_pages_high_priority

如果设置了ALLOC_NO_WATERMARKS标志，会再次调用get_page_from_freelist试图获得所需的页。
但这次会完全忽略水印，因为设置了ALLOC_NO_WATERMARKS。

```
    /* Allocate without watermarks if the context allows */
    if (alloc_flags & ALLOC_NO_WATERMARKS) {
        /*
         * Ignore mempolicies if ALLOC_NO_WATERMARKS on the grounds
         * the allocation is high priority and these type of
         * allocations are system rather than user orientated
         */
        ac->zonelist = node_zonelist(numa_node_id(), gfp_mask);

        page = __alloc_pages_high_priority(gfp_mask, order, ac);

        if (page) {
            goto got_pg;
        }
    }
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__alloc_pages_high_priority.md

### __alloc_pages_direct_compact

从这里内核进入了一条低速路径（slow path），其中会开始一些耗时的操作。前提分配掩码中设置了
__GFP_WAIT标志，因为随后的操作可能使进程睡眠。如果设置了相应的比特位，那么wait是1，否则是0。
如果没有设置该标志，在这里会放弃分配尝试。

```
    /* Atomic allocations - we can't balance anything */
    if (!wait) {
        /*
         * All existing users of the deprecated __GFP_NOFAIL are
         * blockable, so warn of any new users that actually allow this
         * type of allocation to fail.
         */
        WARN_ON_ONCE(gfp_mask & __GFP_NOFAIL);
        goto nopage;
    }

    /* Avoid recursion of direct reclaim */
    if (current->flags & PF_MEMALLOC)
        goto nopage;

    /* Avoid allocations with no watermarks from looping endlessly */
    if (test_thread_flag(TIF_MEMDIE) && !(gfp_mask & __GFP_NOFAIL))
        goto nopage;

    /*
     * Try direct compaction. The first pass is asynchronous. Subsequent
     * attempts after direct reclaim are synchronous
     */
    page = __alloc_pages_direct_compact(gfp_mask, order, alloc_flags, ac,
                    migration_mode,
                    &contended_compaction,
                    &deferred_compaction);
    if (page)
        goto got_pg;
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__alloc_pages_direct_compact.md

### __alloc_pages_direct_reclaim

```
    /* Checks for THP-specific high-order allocations */
    if ((gfp_mask & GFP_TRANSHUGE) == GFP_TRANSHUGE) {
        /*
         * If compaction is deferred for high-order allocations, it is
         * because sync compaction recently failed. If this is the case
         * and the caller requested a THP allocation, we do not want
         * to heavily disrupt the system, so we fail the allocation
         * instead of entering direct reclaim.
         */
        if (deferred_compaction)
            goto nopage;

        /*
         * In all zones where compaction was attempted (and not
         * deferred or skipped), lock contention has been detected.
         * For THP allocation we do not want to disrupt the others
         * so we fallback to base pages instead.
         */
        if (contended_compaction == COMPACT_CONTENDED_LOCK)
            goto nopage;

        /*
         * If compaction was aborted due to need_resched(), we do not
         * want to further increase allocation latency, unless it is
         * khugepaged trying to collapse.
         */
        if (contended_compaction == COMPACT_CONTENDED_SCHED
            && !(current->flags & PF_KTHREAD))
            goto nopage;
    }

    /*
     * It can become very expensive to allocate transparent hugepages at
     * fault, so use asynchronous memory compaction for THP unless it is
     * khugepaged trying to collapse.
     */
    if ((gfp_mask & GFP_TRANSHUGE) != GFP_TRANSHUGE ||
                        (current->flags & PF_KTHREAD))
        migration_mode = MIGRATE_SYNC_LIGHT;

    /* Try direct reclaim and then allocating */
    page = __alloc_pages_direct_reclaim(gfp_mask, order, alloc_flags, ac,
                            &did_some_progress);
    if (page)
        goto got_pg;
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__alloc_pages_direct_reclaim.md

### __alloc_pages_may_oom

如果内核可能执行影响VFS层的调用而又没有设置GFP_NORETRY，那么调用__alloc_pages_may_oom.

如果分配长度小于2^PAGE_ALLOC_COSTLY_ORDER=8页，或设置了__GFP_REPEAT标志，则内核进入无限循环。
在这两种情况下，是不能设置GFP_NORETRY的。因为如果调用者不打算重试，那么进入无限循环重试并
没有意义。内核会跳转回retry标号，即低速路径的入口，并一直等待，直至找到适当大小的内存块——根据
所要分配的内存大小，内核可以假定该无限循环不会持续太长时间.内核在跳转之前会调用wait_iff_congested
等待块设备层队列释放，这样内核就有机会换出页.

在所要求的分配阶大于3但设置了__GFP_NOFAIL标志的情况下，内核也会进入上述无限循环，因为该标志
无论如何都不允许失败。如果情况不是这样，内核只能放弃，并向用户返回NULL指针，并输出一条内存
请求无法满足的警告消息。

```
    /* Do not loop if specifically requested */
    if (gfp_mask & __GFP_NORETRY)
        goto noretry;

    /* Keep reclaiming pages as long as there is reasonable progress */
    pages_reclaimed += did_some_progress;

    if ((did_some_progress && order <= PAGE_ALLOC_COSTLY_ORDER) ||
        ((gfp_mask & __GFP_REPEAT) && pages_reclaimed < (1 << order))) {
        /* Wait for some write requests to complete then retry */
        wait_iff_congested(ac->preferred_zone, BLK_RW_ASYNC, HZ/50);
        goto retry;
    }

    /* Reclaim has failed us, start killing things */
    page = __alloc_pages_may_oom(gfp_mask, order, ac, &did_some_progress);
    if (page)
        goto got_pg;
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__alloc_pages_may_oom.md

### retry

```
    /* Retry as long as the OOM killer is making progress */
    if (did_some_progress)
        goto retry;
```

noretry
----------------------------------------

```
noretry:
    /*
     * High-order allocations do not necessarily loop after
     * direct reclaim and reclaim/compaction depends on compaction
     * being called after reclaim so call directly if necessary
     */
    page = __alloc_pages_direct_compact(gfp_mask, order, alloc_flags,
                        ac, migration_mode,
                        &contended_compaction,
                        &deferred_compaction);
    if (page)
        goto got_pg;
nopage:
    warn_alloc_failed(gfp_mask, order, NULL);
got_pg:
    return page;
}
```
