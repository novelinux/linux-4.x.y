__alloc_pages_may_oom
========================================

Arguments
----------------------------------------

path: mm/page_alloc.c
```
static inline struct page *
__alloc_pages_may_oom(gfp_t gfp_mask, unsigned int order,
    const struct alloc_context *ac, unsigned long *did_some_progress)
{
```

Configure
----------------------------------------

```
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
```

get_page_from_freelist
----------------------------------------

```
    /*
     * Go through the zonelist yet one more time, keep very high watermark
     * here, this is only to catch a parallel oom killing, we must fail if
     * we're still under heavy pressure.
     */
    page = get_page_from_freelist(gfp_mask | __GFP_HARDWALL, order,
                    ALLOC_WMARK_HIGH|ALLOC_CPUSET, ac);
    if (page)
        goto out;
```

Check
----------------------------------------

```
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
```

out_of_memory
----------------------------------------

该函数选择一个内核认为犯有分配过多内存“罪行”的进程，并杀死该进程。这有很大几率腾出较多的空闲页，
然后设置did_some_progress=1触发重试分配内存的操作。但杀死一个进程未必立即出现多于2^PAGE_COSTLY_ORDER
页的连续内存区(其中PAGE_COSTLY_ORDER_PAGES通常设置为3)，因此如果当前要分配如此大的内存区，那么内核
会饶恕所选择的进程，不执行杀死进程的任务，而是承认失败并跳转到nopage。

```
    /* Exhausted what can be done so it's blamo time */
    if (out_of_memory(&oc) || WARN_ON_ONCE(gfp_mask & __GFP_NOFAIL))
        *did_some_progress = 1;
out:
    mutex_unlock(&oom_lock);
    return page;
}
```