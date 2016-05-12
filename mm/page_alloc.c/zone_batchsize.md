zone_batchsize
========================================

zone_batchsize计算得到的batch，大约相当于内存域中页数的0.25‰, 移位操作确保计算结果具有2n-1的形式，
根据经验，该值在大多数系统负载下都能最小化缓存混叠效应。fls是一个特定于计算机的操作，用于算出一个
值中置位的最低比特位。要注意，这种校正会使结果值偏离内存域中页数的0.25‰。batch = 22时偏差最大。
由于22+11-1=32，fls会算出比特位5是最低置位比特位，而1<<5 - 1 = 31。通常情况下偏差都比这小，实际上
是可以忽略的。内存域中的内存数量超出512 MiB时，批量大小并不增长。对于页面大小为4 096 KiB的系统，
如果页数超过131 072，则会达到512 MiB的限制。

对热页来说，下限为0，上限为6*batch，缓存中页的平均数量大约是4*batch，因为内核不会让缓存水平降到
太低。batch* 4相当于内存域中页数的千分之一（这也是zone_batchsize试图将批量大小优化到总页数0.25‰
的原因）。ARM处理器上L2缓存的数量在0.25 MiB～2 MiB之间，因此在冷热缓存中保持更多的内存是无意义的。
根据经验，缓存大小是主内存的千分之一。考虑到当前系统每个CPU配备的物理内存大约在1 GiB～2 GiB，该
规则是有意义的。这样，计算出的批量大小使得冷热缓存中的页有可能放置到CPU的L2缓存中。

path: mm/page_alloc.c
```
static int zone_batchsize(struct zone *zone)
{
#ifdef CONFIG_MMU
    int batch;

    /*
     * The per-cpu-pages pools are set to around 1000th of the
     * size of the zone.  But no more than 1/2 of a meg.
     *
     * OK, so we don't know how big the cache is.  So guess.
     */
    batch = zone->managed_pages / 1024;
    if (batch * PAGE_SIZE > 512 * 1024)
        batch = (512 * 1024) / PAGE_SIZE;
    batch /= 4;        /* We effectively *= 4 below */
    if (batch < 1)
        batch = 1;

    /*
     * Clamp the batch to a 2^n - 1 value. Having a power
     * of 2 value was found to be more likely to have
     * suboptimal cache aliasing properties in some cases.
     *
     * For example if 2 tasks are alternately allocating
     * batches of pages, one task can end up with a lot
     * of pages of one half of the possible page colors
     * and the other with pages of the other colors.
     */
    batch = rounddown_pow_of_two(batch + batch/2) - 1;

    return batch;

#else
    /* The deferral and batching of frees should be suppressed under NOMMU
     * conditions.
     *
     * The problem is that NOMMU needs to be able to allocate large chunks
     * of contiguous memory as there's no hardware page translation to
     * assemble apparent contiguous memory from discontiguous pages.
     *
     * Queueing large contiguous runs of pages for batching, however,
     * causes the pages to actually be freed in smaller chunks.  As there
     * can be a significant delay between the individual batches being
     * recycled, this leads to the once large chunks of space being
     * fragmented and becoming unavailable for high-order allocations.
     */
    return 0;
#endif
}
```