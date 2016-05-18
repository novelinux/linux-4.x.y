__alloc_pages_nodemask
========================================

__alloc_pages是伙伴系统的主函数,其最终调用函数__alloc_pages_nodemask来实现。该函数的实现，
这也是内核中比较冗长的部分之一。特别是在可用内存太少或逐渐用完时，函数就会比较复杂。
如果可用内存足够，则必要的工作会很快完成.

Arguments
----------------------------------------

path: mm/page_alloc.c
```
/*
 * This is the 'heart' of the zoned buddy allocator.
 */
struct page *
__alloc_pages_nodemask(gfp_t gfp_mask, unsigned int order,
            struct zonelist *zonelist, nodemask_t *nodemask)
{
```

### gfp_mask

gfp_mask用来标记需要分配的空闲页的各种属性.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/README.md

Configure
----------------------------------------

### alloc_flags

```
    struct zoneref *preferred_zoneref;
    struct page *page = NULL;
    unsigned int cpuset_mems_cookie;
    int alloc_flags = ALLOC_WMARK_LOW|ALLOC_CPUSET|ALLOC_FAIR;
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/internal.h/ALLOC_WMARK.md

### struct alloc_context

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/struct_alloc_context.md

```
    gfp_t alloc_mask; /* The gfp_t that was actually used for allocation */
    struct alloc_context ac = {
        .high_zoneidx = gfp_zone(gfp_mask),
        .nodemask = nodemask,
        .migratetype = gfpflags_to_migratetype(gfp_mask),
    };
```

#### gfp_zone

使用gfp_mask寻找合适的zone type.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/gfp_zone.md

#### gfpflags_to_migratetype

使用gfp_mask寻找合适的migrate type.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/gfpflags_to_migratetype.md

### Check

```
    gfp_mask &= gfp_allowed_mask;

    lockdep_trace_alloc(gfp_mask);

    might_sleep_if(gfp_mask & __GFP_WAIT);

    if (should_fail_alloc_page(gfp_mask, order))
        return NULL;

    /*
     * Check the zones suitable for the gfp_mask contain at least one
     * valid zone. It's possible to have an empty zonelist as a result
     * of __GFP_THISNODE and a memoryless node
     */
    /* 如果在没有内存的结点上使用GFP_THISNODE，导致zonelist为空，就会发生这种情况 */
    if (unlikely(!zonelist->_zonerefs->zone))
        return NULL;

    if (IS_ENABLED(CONFIG_CMA) && ac.migratetype == MIGRATE_MOVABLE)
        alloc_flags |= ALLOC_CMA;
```

retry_cpuset
----------------------------------------

```
retry_cpuset:
    cpuset_mems_cookie = read_mems_allowed_begin();

    /* We set it here, as __alloc_pages_slowpath might have changed it */
    ac.zonelist = zonelist;
    /* The preferred zone is used for statistics later */
    preferred_zoneref = first_zones_zonelist(ac.zonelist, ac.high_zoneidx,
                ac.nodemask ? : &cpuset_current_mems_allowed,
                &ac.preferred_zone);
    if (!ac.preferred_zone)
        goto out;
    ac.classzone_idx = zonelist_zone_idx(preferred_zoneref);

    /* First allocation attempt */
    alloc_mask = gfp_mask|__GFP_HARDWALL;
```

### get_page_from_freelist

在最简单的情形中，分配空闲内存区只涉及调用一次get_page_from_freelist，然后返回所需数目的页.

```
    page = get_page_from_freelist(alloc_mask, order, alloc_flags, &ac);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/get_page_from_freelist.md

### __alloc_pages_slowpath

第一次内存分配尝试不会特别积极。如果在某个内存域中无法找到空闲内存，则意味着内存没剩下多少了，
内核需要增加较多的工作量才能找到更多内存.

```
    if (unlikely(!page)) {
        /*
         * Runtime PM, block IO and its error handling path
         * can deadlock because I/O on the device might not
         * complete.
         */
        alloc_mask = memalloc_noio_flags(gfp_mask);

        page = __alloc_pages_slowpath(alloc_mask, order, &ac);
    }

    if (kmemcheck_enabled && page)
        kmemcheck_pagealloc_alloc(page, order, gfp_mask);

    trace_mm_page_alloc(page, order, alloc_mask, ac.migratetype);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__alloc_pages_slowpath.md

retry_cpuset
----------------------------------------

```
out:
    /*
     * When updating a task's mems_allowed, it is possible to race with
     * parallel threads in such a way that an allocation can fail while
     * the mask is being updated. If a page allocation is about to fail,
     * check if the cpuset changed during allocation and if so, retry.
     */
    if (unlikely(!page && read_mems_allowed_retry(cpuset_mems_cookie)))
        goto retry_cpuset;

    return page;
}
EXPORT_SYMBOL(__alloc_pages_nodemask);
```