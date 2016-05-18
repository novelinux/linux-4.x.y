struct zone
========================================

每个结点的内存被分为多个块，称为zones，它表示内存中一段区域。一个zone用struct zone结构描述，
zone的类型主要有ZONE_DMA、ZONE_NORMAL和ZONE_HIGHMEM。ZONE_DMA位于低端的内存空间，
用于某些旧的ISA设备。ZONE_NORMAL的内存直接映射到Linux内核线性地址空间的高端部分，许多内核操作
只能在ZONE_NORMAL中进行

该结构比较特殊的方面是它由ZONE_PADDING分隔为几个部分。这是因为对zone结构的访问非常频繁。
在多处理器系统上，通常会有不同的CPU试图同时访问结构成员。因此使用锁防止它们彼此干扰，
避免错误和不一致。由于内核对该结构的访问非常频繁，因此会经常性地获取该结构的两个自旋锁
zone->lock和zone->lru_lock。如果数据保存在CPU高速缓存中，那么会处理得更快速。高速缓存分为行，
每一行负责不同的内存区。内核使用ZONE_PADDING宏生成“填充”字段添加到结构中，以确保每个自旋锁
都处于自身的缓存行中。

该结构的最后两个部分也通过填充字段彼此分隔开来。两者都不包含锁，主要目的是将数据保持在一个缓存行
中，便于快速访问，从而无需从内存加载数据（与CPU高速缓存相比，内存比较慢）。由于填充造成结构长度
的增加是可以忽略的，特别是在内核内存中zone结构的实例相对很少。

对于zone相关信息可从zoneinfo文件中获取:

```
# cat /proc/zoneinfo
```

watermark
----------------------------------------

path: include/linux/mmzone.h
```
#ifndef __GENERATING_BOUNDS_H

struct zone {
    /* Read-mostly fields */

    /* zone watermarks, access with *_wmark_pages(zone) macros */
    unsigned long watermark[NR_WMARK];
```

当系统中可用的内存比较少时，kswapd将被唤醒，并进行页交换。如果需要内存的压力非常大，进程将
同步释放内存。每个zone有三个阈值，用于跟踪该zone的内存压力。watermark[WMARK_MIN]的页框数是由
内存初始化free_area_init_core函数，根据该zone内页框的比例计算的，最小值为20页，最大值一般为255页。

* 当到达watermark[WMARK_MIN]时，分配器将采用同步方式进行kswapd的工作;
* 当空闲页的数目达到watermark[WMARK_LOW]时，kswapd被buddy分配器唤醒，开始释放页；
* 当达到watermark[WMARK_HIGH]时，kswapd将被唤醒，此时kswapd不会考虑如何平衡该zone，直到有
  watermark[WMARK_HIGH]空闲页为止。

一般情况下，watermark[WMARK_HIGH]缺省值是watermark[WMARK_MIN]的3倍。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/enum_zone_watermarks.md

lowmem_reserve
----------------------------------------

```
    /*
     * We don't know if the memory that we're going to allocate will be freeable
     * or/and it will be released eventually, so to avoid totally wasting several
     * GB of ram we must reserve some of the lower zone memory (otherwise we risk
     * to run OOM on the lower zones despite there's tons of freeable ram
     * on the higher zones). This array is recalculated at runtime if the
     * sysctl_lowmem_reserve_ratio sysctl changes.
     */
    long lowmem_reserve[MAX_NR_ZONES];
```

数组分别为各种内存域指定了若干页，用于一些无论如何都不能失败的关键性内存分配。各个内存域的份额
根据重要性确定。

zone_pgdat
----------------------------------------

```
#ifdef CONFIG_NUMA
    int node;
#endif

    /*
     * The target ratio of ACTIVE_ANON to INACTIVE_ANON pages on
     * this zone's LRU.  Maintained by the pageout code.
     */
    unsigned int inactive_ratio;

    struct pglist_data    *zone_pgdat;
```

内存域和父结点之间的关联由zone_pgdat建立，zone_pgdat指向对应的pg_list_data实例。

pageset
----------------------------------------

```
    struct per_cpu_pageset __percpu *pageset;
```

struct zone的pageset成员用于实现冷热分配器(hot-n-cold allocator)。内核说页是热的，意味着页已经
加载到CPU高速缓存，与在内存中的页相比，其数据能够更快地访问。相反，冷页则不在高速缓存中。在
多处理器系统上每个CPU都有一个或多个高速缓存，各个CPU的管理必须是独立的。
尽管内存域可能属于一个特定的NUMA结点，因而关联到某个特定的CPU，但其他CPU的高速缓存仍然可以包含
该内存域中的页。最终的效果是，每个处理器都可以访问系统中所有的页，尽管速度不同。因此，特定于
内存域的数据结构不仅要考虑到所属NUMA结点相关的CPU，还必须照顾到系统中其他的CPU。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/struct_per_cpu_pageset.md

pageblock_flags
----------------------------------------

```
    /*
     * This is a per-zone reserve of pages that should not be
     * considered dirtyable memory.
     */
    unsigned long        dirty_balance_reserve;

#ifndef CONFIG_SPARSEMEM
    /*
     * Flags for a pageblock_nr_pages block. See pageblock-flags.h.
     * In SPARSEMEM, this map is stored in struct mem_section
     */
    unsigned long        *pageblock_flags;
#endif /* CONFIG_SPARSEMEM */
```

zone_start_pfn
----------------------------------------

```
#ifdef CONFIG_NUMA
    /*
     * zone reclaim becomes active if more unmapped pages exist.
     */
    unsigned long        min_unmapped_pages;
    unsigned long        min_slab_pages;
#endif /* CONFIG_NUMA */

    /* zone_start_pfn == zone_start_paddr >> PAGE_SHIFT */
    unsigned long        zone_start_pfn;
```

是内存域第一个页帧的索引

spanned_pages
----------------------------------------

```
    /*
     * spanned_pages is the total pages spanned by the zone, including
     * holes, which is calculated as:
     *     spanned_pages = zone_end_pfn - zone_start_pfn;
     *
     * present_pages is physical pages existing within the zone, which
     * is calculated as:
     *    present_pages = spanned_pages - absent_pages(pages in holes);
     *
     * managed_pages is present pages managed by the buddy system, which
     * is calculated as (reserved_pages includes pages allocated by the
     * bootmem allocator):
     *    managed_pages = present_pages - reserved_pages;
     *
     * So present_pages may be used by memory hotplug or memory power
     * management logic to figure out unmanaged pages by checking
     * (present_pages - managed_pages). And managed_pages should be used
     * by page allocator and vm scanner to calculate all kinds of watermarks
     * and thresholds.
     *
     * Locking rules:
     *
     * zone_start_pfn and spanned_pages are protected by span_seqlock.
     * It is a seqlock because it has to be read outside of zone->lock,
     * and it is done in the main allocator path.  But, it is written
     * quite infrequently.
     *
     * The span_seq lock is declared along with zone->lock because it is
     * frequently read in proximity to zone->lock.  It's good to
     * give them a chance of being in the same cacheline.
     *
     * Write access to present_pages at runtime should be protected by
     * mem_hotplug_begin/end(). Any reader who can't tolerant drift of
     * present_pages should get_online_mems() to get a stable value.
     *
     * Read access to managed_pages should be safe because it's unsigned
     * long. Write access to zone->managed_pages and totalram_pages are
     * protected by managed_page_count_lock at runtime. Idealy only
     * adjust_managed_page_count() should be used instead of directly
     * touching zone->managed_pages and totalram_pages.
     */
    unsigned long        managed_pages;
    unsigned long        spanned_pages;
    unsigned long        present_pages;
```

指定内存域中页的总数，但并非所有都是可用的。内存域中可能有一些小的空洞。另一个计数器
present_pages则给出了实际上可用的页数目。该计数器的值通常与spanned_pages相同。

name
----------------------------------------

```
    const char        *name;
```

是一个字符串，保存该内存域的惯用名称。目前有3个选项可用: Normal、DMA和HighMem.

wait_table vs wait_table_bits vs wait_table_hash_nr_entries
----------------------------------------

```
    /*
     * Number of MIGRATE_RESEVE page block. To maintain for just
     * optimization. Protected by zone->lock.
     */
    int            nr_migrate_reserve_block;

#ifdef CONFIG_MEMORY_ISOLATION
    /*
     * Number of isolated pageblock. It is used to solve incorrect
     * freepage counting problem due to racy retrieving migratetype
     * of pageblock. Protected by zone->lock.
     */
    unsigned long        nr_isolate_pageblock;
#endif

#ifdef CONFIG_MEMORY_HOTPLUG
    /* see spanned/present_pages for more description */
    seqlock_t        span_seqlock;
#endif

    /*
     * wait_table        -- the array holding the hash table
     * wait_table_hash_nr_entries    -- the size of the hash table array
     * wait_table_bits    -- wait_table_size == (1 << wait_table_bits)
     *
     * The purpose of all these is to keep track of the people
     * waiting for a page to become available and make them
     * runnable again when possible. The trouble is that this
     * consumes a lot of space, especially when so few things
     * wait on pages at a given time. So instead of using
     * per-page waitqueues, we use a waitqueue hash table.
     *
     * The bucket discipline is to sleep on the same queue when
     * colliding and wake all in that wait queue when removing.
     * When something wakes, it must check to be sure its page is
     * truly available, a la thundering herd. The cost of a
     * collision is great, but given the expected load of the
     * table, they should be so rare as to be outweighed by the
     * benefits from the saved space.
     *
     * __wait_on_page_locked() and unlock_page() in mm/filemap.c, are the
     * primary users of these fields, and in mm/page_alloc.c
     * free_area_init_core() performs the initialization of them.
     */
    wait_queue_head_t    *wait_table;
    unsigned long        wait_table_hash_nr_entries;
    unsigned long        wait_table_bits;
```

实现了一个等待队列，可用于进程等待某一页变为可用。直观的概念是很好理解的: 进程排成一个队列，
等待某些条件。在条件变为真时，内核会通知进程恢复工作。

free_area
----------------------------------------

```
    ZONE_PADDING(_pad1_)

    /* Write-intensive fields used from the page allocator */
    spinlock_t        lock;

    /* free areas of different sizes */
    struct free_area    free_area[MAX_ORDER];
```

是同名数据结构的数组，用于实现伙伴系统。每个数组元素都表示某种固定长度的一些连续内存区。
对于包含在每个区域中的空闲内存页的管理，free_area是一个起点。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/struct_free_area.md

### MAX_ORDER

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/mmzone.h/MAX_ORDER.md

free_area[]数组中各个元素的索引也解释为阶，用于指定对应链表中的连续内存区包含多少个页帧。
第0个链表包含的内存区为单页(20=1),第1个链表管理的内存区为两页(21=2),
第3个管理的内存区为4页，依次类推...

内存区是如何连接的？内存区中第1页内的链表元素，可用于将内存区维持在链表中。因此，也不必引入
新的数据结构来管理物理上连续的页，否则这些页不可能在同一内存区中。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/res/free_area.jpg

flags
----------------------------------------

```
    /* zone flags, see below */
    unsigned long        flags;
```

描述内存域的当前状态。允许使用下列标志：

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/enum_zone_flags.md

lruvec
----------------------------------------

```
    ZONE_PADDING(_pad2_)

    /* Write-intensive fields used by page reclaim */

    /* Fields commonly accessed by the page reclaim scanner */
    spinlock_t        lru_lock;
    struct lruvec        lruvec;
```

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/struct_lruvec.md

vm_stat
----------------------------------------

```
    /* Evictions & activations on the inactive file list */
    atomic_long_t        inactive_age;

    /*
     * When free pages are below this point, additional steps are taken
     * when reading the number of free pages to avoid per-cpu counter
     * drift allowing watermarks to be breached
     */
    unsigned long percpu_drift_mark;

#if defined CONFIG_COMPACTION || defined CONFIG_CMA
    /* pfn where compaction free scanner should start */
    unsigned long        compact_cached_free_pfn;
    /* pfn where async and sync compaction migration scanner should start */
    unsigned long        compact_cached_migrate_pfn[2];
#endif

#ifdef CONFIG_COMPACTION
    /*
     * On compaction failure, 1<<compact_defer_shift compactions
     * are skipped before trying again. The number attempted since
     * last failure is tracked with compact_considered.
     */
    unsigned int        compact_considered;
    unsigned int        compact_defer_shift;
    int            compact_order_failed;
#endif

#if defined CONFIG_COMPACTION || defined CONFIG_CMA
    /* Set to true when the PG_migrate_skip bits should be cleared */
    bool            compact_blockskip_flush;
#endif

    ZONE_PADDING(_pad3_)
    /* Zone statistics */
    atomic_long_t        vm_stat[NR_VM_ZONE_STAT_ITEMS];
```

维护了大量有关该内存域的统计信息。由于其中维护的大部分信息目前没有多大意义.


____cacheline_internodealigned_in_smp
----------------------------------------

```
} ____cacheline_internodealigned_in_smp;
```

还使用了编译器关键字__cache-line_maxaligned_in_smp，用以实现最优的高速缓存对齐方式。
