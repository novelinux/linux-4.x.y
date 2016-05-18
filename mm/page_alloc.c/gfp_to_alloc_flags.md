gfp_to_alloc_flags
========================================

path: mm/page_alloc.c
```
static inline int
gfp_to_alloc_flags(gfp_t gfp_mask)
{
    int alloc_flags = ALLOC_WMARK_MIN | ALLOC_CPUSET;
    const bool atomic = !(gfp_mask & (__GFP_WAIT | __GFP_NO_KSWAPD));

    /* __GFP_HIGH is assumed to be the same as ALLOC_HIGH to save a branch. */
    BUILD_BUG_ON(__GFP_HIGH != (__force gfp_t) ALLOC_HIGH);

    /*
     * The caller may dip into page reserves a bit more if the caller
     * cannot run direct reclaim, or if the caller has realtime scheduling
     * policy or is asking for __GFP_HIGH memory.  GFP_ATOMIC requests will
     * set both ALLOC_HARDER (atomic == true) and ALLOC_HIGH (__GFP_HIGH).
     */
    alloc_flags |= (__force int) (gfp_mask & __GFP_HIGH);

    if (atomic) {
        /*
         * Not worth trying to allocate harder for __GFP_NOMEMALLOC even
         * if it can't schedule.
         */
        if (!(gfp_mask & __GFP_NOMEMALLOC))
            alloc_flags |= ALLOC_HARDER;
        /*
         * Ignore cpuset mems for GFP_ATOMIC rather than fail, see the
         * comment for __cpuset_node_allowed().
         */
        alloc_flags &= ~ALLOC_CPUSET;
    } else if (unlikely(rt_task(current)) && !in_interrupt())
        alloc_flags |= ALLOC_HARDER;

    if (likely(!(gfp_mask & __GFP_NOMEMALLOC))) {
        if (gfp_mask & __GFP_MEMALLOC)
            alloc_flags |= ALLOC_NO_WATERMARKS;
        else if (in_serving_softirq() && (current->flags & PF_MEMALLOC))
            alloc_flags |= ALLOC_NO_WATERMARKS;
        /* 如果设置了PF_MEMALLOC或进程设置了TIF_MEMDIE标志（在这两种情况下，内核不能处于
         * 中断上下文中）, 将alloc_flags设置ALLOC_NO_WATERMARKS标志, 通常只有在分配器自身
         * 需要更多内存时，才会设置PF_MEMALLOC，而只有在线程刚好被OOM killer机制选中时，
         * 才会设置TIF_MEMDIE。
         */
        else if (!in_interrupt() &&
                ((current->flags & PF_MEMALLOC) ||
                 unlikely(test_thread_flag(TIF_MEMDIE))))
            alloc_flags |= ALLOC_NO_WATERMARKS;
    }
#ifdef CONFIG_CMA
    if (gfpflags_to_migratetype(gfp_mask) == MIGRATE_MOVABLE)
        alloc_flags |= ALLOC_CMA;
#endif
    return alloc_flags;
}
```