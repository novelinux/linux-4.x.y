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

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/mmzone.h/struct_zone.md
