__alloc_pages_nodemask
========================================

path: mm/page_alloc.c
```
/*
 * This is the 'heart' of the zoned buddy allocator.
 */
struct page *
__alloc_pages_nodemask(gfp_t gfp_mask, unsigned int order,
            struct zonelist *zonelist, nodemask_t *nodemask)
{
    struct zoneref *preferred_zoneref;
    struct page *page = NULL;
    unsigned int cpuset_mems_cookie;
    int alloc_flags = ALLOC_WMARK_LOW|ALLOC_CPUSET|ALLOC_FAIR;
    gfp_t alloc_mask; /* The gfp_t that was actually used for allocation */
    struct alloc_context ac = {
        .high_zoneidx = gfp_zone(gfp_mask),
        .nodemask = nodemask,
        .migratetype = gfpflags_to_migratetype(gfp_mask),
    };

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
    if (unlikely(!zonelist->_zonerefs->zone))
        return NULL;

    if (IS_ENABLED(CONFIG_CMA) && ac.migratetype == MIGRATE_MOVABLE)
        alloc_flags |= ALLOC_CMA;

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
    page = get_page_from_freelist(alloc_mask, order, alloc_flags, &ac);
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