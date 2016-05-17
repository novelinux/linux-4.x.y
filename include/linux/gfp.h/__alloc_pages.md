__alloc_pages
========================================

path: include/linux/gfp.h
```
struct page *
__alloc_pages_nodemask(gfp_t gfp_mask, unsigned int order,
                       struct zonelist *zonelist, nodemask_t *nodemask);

static inline struct page *
__alloc_pages(gfp_t gfp_mask, unsigned int order,
                              struct zonelist *zonelist)
{
    return __alloc_pages_nodemask(gfp_mask, order, zonelist, NULL);
}
```

__alloc_pages_nodemask
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__alloc_pages_nodemask.md
