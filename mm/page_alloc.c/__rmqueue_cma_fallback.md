__rmqueue_cma_fallback
========================================

path: mm/page_alloc.c
```
#ifdef CONFIG_CMA
static struct page *__rmqueue_cma_fallback(struct zone *zone,
                    unsigned int order)
{
    return __rmqueue_smallest(zone, order, MIGRATE_CMA);
}
#else
static inline struct page *__rmqueue_cma_fallback(struct zone *zone,
                    unsigned int order) { return NULL; }
#endif
```

__rmqueue_smallest
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/mm/page_alloc.c/__rmqueue_smallest.md
