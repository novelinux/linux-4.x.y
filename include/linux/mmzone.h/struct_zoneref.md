struct zoneref
========================================

path: include/linux/mmzone.h
```
/*
 * This struct contains information about a zone in a zonelist. It is stored
 * here to avoid dereferences into large structures and lookups of tables
 */
struct zoneref {
    struct zone *zone;    /* Pointer to actual zone */
    int zone_idx;         /* zone_idx(zoneref->zone) */
};
```

struct zone
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/struct_zone.md
