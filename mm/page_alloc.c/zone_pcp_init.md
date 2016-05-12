zone_pcp_init
========================================

path: mm/page_alloc.c
```
static __meminit void zone_pcp_init(struct zone *zone)
{
    /*
     * per cpu subsystem is not up at this point. The following code
     * relies on the ability of the linker to provide the
     * offset of a (static) per cpu variable into the per cpu area.
     */
    zone->pageset = &boot_pageset;

    if (populated_zone(zone))
        printk(KERN_DEBUG "  %s zone: %lu pages, LIFO batch:%u\n",
            zone->name, zone->present_pages,
                     zone_batchsize(zone));
}
```

boot_pageset
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/boot_pageset.md

populated_zone
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/populated_zone.md
