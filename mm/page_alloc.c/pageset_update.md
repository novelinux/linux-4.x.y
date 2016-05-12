pageset_update
========================================

path: mm/page_alloc.c
```
/*
 * pcp->high and pcp->batch values are related and dependent on one another:
 * ->batch must never be higher then ->high.
 * The following function updates them in a safe manner without read side
 * locking.
 *
 * Any new users of pcp->batch and pcp->high should ensure they can cope with
 * those fields changing asynchronously (acording the the above rule).
 *
 * mutex_is_locked(&pcp_batch_high_lock) required when calling this function
 * outside of boot time (or some other assurance that no concurrent updaters
 * exist).
 */
static void pageset_update(struct per_cpu_pages *pcp, unsigned long high,
        unsigned long batch)
{
       /* start with a fail safe value for batch */
    pcp->batch = 1;
    smp_wmb();

       /* Update high, then batch, in order */
    pcp->high = high;
    smp_wmb();

    pcp->batch = batch;
}
```