setup_per_cpu_pageset
========================================

path: mm/page_alloc.c
```
/*
 * Allocate per cpu pagesets and initialize them.
 * Before this call only boot pagesets were available.
 */
void __init setup_per_cpu_pageset(void)
{
    struct zone *zone;

    for_each_populated_zone(zone)
        setup_zone_pageset(zone);
}
```

setup_zone_pageset
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/setup_zone_pageset.md
