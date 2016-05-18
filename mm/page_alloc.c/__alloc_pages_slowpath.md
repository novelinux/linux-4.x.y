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

### get_page_from_freelist

在交换守护进程唤醒后，内核开始新的尝试，在内存域之一查找适当的内存块。这一次进行的搜索更为积极，
对分配标志进行了调整，修改为一些在当前特定情况下更有可能分配成功的标志。同时，将水印降低到最小值。
对实时进程和指定了__GFP_WAIT标志因而不能睡眠的调用。然后用修改的标志集，再一次调用
get_page_from_freelist，试图获得所需的页。

```
    /*
     * OK, we're below the kswapd watermark and have kicked background
     * reclaim. Now things get more complex, so set up alloc_flags according
     * to how we want to proceed.
     */
    alloc_flags = gfp_to_alloc_flags(gfp_mask);

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