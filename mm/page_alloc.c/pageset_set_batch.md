pageset_set_batch
========================================

path: mm/page_alloc.c
```
/* a companion to pageset_set_high() */
static void pageset_set_batch(struct per_cpu_pageset *p, unsigned long batch)
{
    pageset_update(&p->pcp, 6 * batch, max(1UL, 1 * batch));
}
```

pageset_update
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/pageset_update.md
