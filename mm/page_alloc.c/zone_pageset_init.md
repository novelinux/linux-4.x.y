zone_pageset_init
========================================

path: mm/page_alloc.c
```
static void __meminit zone_pageset_init(struct zone *zone, int cpu)
{
    struct per_cpu_pageset *pcp = per_cpu_ptr(zone->pageset, cpu);

    pageset_init(pcp);
    pageset_set_high_and_batch(zone, pcp);
}
```

pageset_init
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/pageset_init.md

pageset_set_high_and_batch
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/pageset_set_high_and_batch.md
