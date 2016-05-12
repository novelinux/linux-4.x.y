pageset_set_high_and_batch
========================================

path: mm/page_alloc.c
```
static void pageset_set_high_and_batch(struct zone *zone,
                       struct per_cpu_pageset *pcp)
{
    if (percpu_pagelist_fraction)
        pageset_set_high(pcp,
            (zone->managed_pages /
                percpu_pagelist_fraction));
    else
        pageset_set_batch(pcp, zone_batchsize(zone));
}
```

zone_batchsize
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/zone_batchsize.md

pageset_set_batch
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/pageset_set_batch.md
