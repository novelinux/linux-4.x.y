__alloc_pages_may_oom
========================================

path: mm/page_alloc.c
```
static inline struct page *
__alloc_pages_may_oom(gfp_t gfp_mask, unsigned int order,
    const struct alloc_context *ac, unsigned long *did_some_progress)
{
    struct oom_control oc = {
        .zonelist = ac->zonelist,
        .nodemask = ac->nodemask,
        .gfp_mask = gfp_mask,
        .order = order,
    };
    struct page *page;

    *did_some_progress = 0;

    /*
     * Acquire the oom lock.  If that fails, somebody else is
     * making progress for us.
     */
    if (!mutex_trylock(&oom_lock)) {
        *did_some_progress = 1;
        schedule_timeout_uninterruptible(1);
        return NULL;
    }

    /*
     * Go through the zonelist yet one more time, keep very high watermark
     * here, this is only to catch a parallel oom killing, we must fail if
     * we're still under heavy pressure.
     */
    page = get_page_from_freelist(gfp_mask | __GFP_HARDWALL, order,
                    ALLOC_WMARK_HIGH|ALLOC_CPUSET, ac);
    if (page)
        goto out;

    if (!(gfp_mask & __GFP_NOFAIL)) {
        /* Coredumps can quickly deplete all memory reserves */
        if (current->flags & PF_DUMPCORE)
            goto out;
        /* The OOM killer will not help higher order allocs */
        if (order > PAGE_ALLOC_COSTLY_ORDER)
            goto out;
        /* The OOM killer does not needlessly kill tasks for lowmem */
        if (ac->high_zoneidx < ZONE_NORMAL)
            goto out;
        /* The OOM killer does not compensate for IO-less reclaim */
        if (!(gfp_mask & __GFP_FS)) {
            /*
             * XXX: Page reclaim didn't yield anything,
             * and the OOM killer can't be invoked, but
             * keep looping as per tradition.
             */
            *did_some_progress = 1;
            goto out;
        }
        if (pm_suspended_storage())
            goto out;
        /* The OOM killer may not free memory on a specific node */
        if (gfp_mask & __GFP_THISNODE)
            goto out;
    }
    /* Exhausted what can be done so it's blamo time */
    if (out_of_memory(&oc) || WARN_ON_ONCE(gfp_mask & __GFP_NOFAIL))
        *did_some_progress = 1;
out:
    mutex_unlock(&oom_lock);
    return page;
}
```