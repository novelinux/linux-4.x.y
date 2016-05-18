get_page_from_freelist
========================================

get_page_from_freelist是伙伴系统使用的另一个重要的辅助函数。它通过标志集和分配阶来判断是否能
进行分配。如果可以，则发起实际的分配操作。

Arguments
----------------------------------------

path: mm/page_alloc.c
```
/*
 * get_page_from_freelist goes through the zonelist trying to allocate
 * a page.
 */
static struct page *
get_page_from_freelist(gfp_t gfp_mask, unsigned int order, int alloc_flags,
                        const struct alloc_context *ac)
{
```

Configure
----------------------------------------

```
    /* 该函数的一个参数是指向备用列表的指针。在预期内存域没有空闲空间的情况下，该列表确定了
     * 扫描系统其他内存域（和结点）的顺序。
     */
    struct zonelist *zonelist = ac->zonelist;
    struct zoneref *z;
    struct page *page = NULL;
    struct zone *zone;
    nodemask_t *allowednodes = NULL;/* zonelist_cache approximation */
    int zlc_active = 0;        /* set if using zonelist_cache */
    int did_zlc_setup = 0;        /* just call zlc_setup() one time */
    bool consider_zone_dirty = (alloc_flags & ALLOC_WMARK_LOW) &&
                (gfp_mask & __GFP_WRITE);
    int nr_fair_skipped = 0;
    bool zonelist_rescan;
```

Scan zonelist
----------------------------------------

### Check

遍历备用列表的所有内存域，用最简单的方式查找一个适当的空闲内存块。
首先，解释ALLOC_*标志(cpuset_zone_allowed_softwall是另一个辅助函数，
用于检查给定内存域是否属于该进程允许运行的CPU)

```
zonelist_scan:
    zonelist_rescan = false;

    /*
     * Scan zonelist, looking for a zone with enough free.
     * See also __cpuset_node_allowed() comment in kernel/cpuset.c.
     */
    for_each_zone_zonelist_nodemask(zone, z, zonelist, ac->high_zoneidx,
                                ac->nodemask) {
        unsigned long mark;

        if (IS_ENABLED(CONFIG_NUMA) && zlc_active &&
            !zlc_zone_worth_trying(zonelist, z, allowednodes))
                continue;
        if (cpusets_enabled() &&
            (alloc_flags & ALLOC_CPUSET) &&
            !cpuset_zone_allowed(zone, gfp_mask))
                continue;
        /*
         * Distribute pages in proportion to the individual
         * zone size to ensure fair page aging.  The zone a
         * page was allocated in should have no effect on the
         * time the page has in memory before being reclaimed.
         */
        if (alloc_flags & ALLOC_FAIR) {
            if (!zone_local(ac->preferred_zone, zone))
                break;
            if (test_bit(ZONE_FAIR_DEPLETED, &zone->flags)) {
                nr_fair_skipped++;
                continue;
            }
        }
        /*
         * When allocating a page cache page for writing, we
         * want to get it from a zone that is within its dirty
         * limit, such that no single zone holds more than its
         * proportional share of globally allowed dirty pages.
         * The dirty limits take into account the zone's
         * lowmem reserves and high watermark so that kswapd
         * should be able to balance it without having to
         * write pages from its LRU list.
         *
         * This may look like it could increase pressure on
         * lower zones by failing allocations in higher zones
         * before they are full.  But the pages that do spill
         * over are limited as the lower zones are protected
         * by this very same mechanism.  It should not become
         * a practical burden to them.
         *
         * XXX: For now, allow allocations to potentially
         * exceed the per-zone dirty limit in the slowpath
         * (ALLOC_WMARK_LOW unset) before going into reclaim,
         * which is important when on a NUMA setup the allowed
         * zones are together not big enough to reach the
         * global limit.  The proper fix for these situations
         * will require awareness of zones in the
         * dirty-throttling and the flusher threads.
         */
        if (consider_zone_dirty && !zone_dirty_ok(zone))
            continue;
```

### zone_watermark_ok

zone_watermark_ok接下来检查所遍历到的内存域是否有足够的空闲页,并试图分配一个连续内存块。
如果两个条件之一不能满足，即或者没有足够的空闲页，或者没有连续内存块可满足分配请求，
则循环进行到备用列表中的下一个内存域，作同样的检查。

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/zone_watermark_ok.md

```
        mark = zone->watermark[alloc_flags & ALLOC_WMARK_MASK];
        if (!zone_watermark_ok(zone, order, mark,
                       ac->classzone_idx, alloc_flags)) {
            int ret;

            /* Checked here to keep the fast path fast */
            BUILD_BUG_ON(ALLOC_NO_WATERMARKS < NR_WMARK);
            if (alloc_flags & ALLOC_NO_WATERMARKS)
                goto try_this_zone;

            if (IS_ENABLED(CONFIG_NUMA) &&
                    !did_zlc_setup && nr_online_nodes > 1) {
                /*
                 * we do zlc_setup if there are multiple nodes
                 * and before considering the first zone allowed
                 * by the cpuset.
                 */
                allowednodes = zlc_setup(zonelist, alloc_flags);
                zlc_active = 1;
                did_zlc_setup = 1;
            }

            if (zone_reclaim_mode == 0 ||
                !zone_allows_reclaim(ac->preferred_zone, zone))
                goto this_zone_full;

            /*
             * As we may have just activated ZLC, check if the first
             * eligible zone has failed zone_reclaim recently.
             */
            if (IS_ENABLED(CONFIG_NUMA) && zlc_active &&
                !zlc_zone_worth_trying(zonelist, z, allowednodes))
                continue;

            ret = zone_reclaim(zone, gfp_mask, order);
            switch (ret) {
            case ZONE_RECLAIM_NOSCAN:
                /* did not scan */
                continue;
            case ZONE_RECLAIM_FULL:
                /* scanned but unreclaimable */
                continue;
            default:
                /* did we reclaim enough */
                if (zone_watermark_ok(zone, order, mark,
                        ac->classzone_idx, alloc_flags))
                    goto try_this_zone;

                /*
                 * Failed to reclaim enough to meet watermark.
                 * Only mark the zone full if checking the min
                 * watermark or if we failed to reclaim just
                 * 1<<order pages or else the page allocator
                 * fastpath will prematurely mark zones full
                 * when the watermark is between the low and
                 * min watermarks.
                 */
                if (((alloc_flags & ALLOC_WMARK_MASK) == ALLOC_WMARK_MIN) ||
                    ret == ZONE_RECLAIM_SOME)
                    goto this_zone_full;

                continue;
            }
        }
```

### try_this_zone

如果内存域适用于当前的分配请求，那么buffered_rmqueue试图从中分配所需数目的页,
如果分配成功，则将页返回给调用者。否则，进入下一个循环，选择备用列表中的下一个内存域。

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/buffered_rmqueue.md

```
try_this_zone:
        page = buffered_rmqueue(ac->preferred_zone, zone, order,
                        gfp_mask, ac->migratetype);
```

#### prep_new_page

在返回指针之前，prep_new_page需要做一些准备工作，以便内核能够处理这些页.

```
        if (page) {
            if (prep_new_page(page, order, gfp_mask, alloc_flags))
                goto try_this_zone;
            return page;
        }
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/prep_new_page.md

### this_zone_full

```
this_zone_full:
       if (IS_ENABLED(CONFIG_NUMA) && zlc_active)
            zlc_mark_zone_full(zonelist, z);
    }
```

Rescan zonelist
----------------------------------------

```
    /*
     * The first pass makes sure allocations are spread fairly within the
     * local node.  However, the local node might have free pages left
     * after the fairness batches are exhausted, and remote zones haven't
     * even been considered yet.  Try once more without fairness, and
     * include remote zones now, before entering the slowpath and waking
     * kswapd: prefer spilling to a remote zone over swapping locally.
     */
    if (alloc_flags & ALLOC_FAIR) {
        alloc_flags &= ~ALLOC_FAIR;
        if (nr_fair_skipped) {
            zonelist_rescan = true;
            reset_alloc_batches(ac->preferred_zone);
        }
        if (nr_online_nodes > 1)
            zonelist_rescan = true;
    }

    if (unlikely(IS_ENABLED(CONFIG_NUMA) && zlc_active)) {
        /* Disable zlc cache for second zonelist scan */
        zlc_active = 0;
        zonelist_rescan = true;
    }

    if (zonelist_rescan)
        goto zonelist_scan;

    return NULL;
}
```
