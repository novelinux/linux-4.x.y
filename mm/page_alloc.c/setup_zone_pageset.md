setup_zone_pageset
========================================

path: mm/page_alloc.c
```
static void __meminit setup_zone_pageset(struct zone *zone)
{
    int cpu;
    zone->pageset = alloc_percpu(struct per_cpu_pageset);
    for_each_possible_cpu(cpu)
        zone_pageset_init(zone, cpu);
}
```

zone_pageset_init
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/zone_pageset_init.md
