populated_zone
========================================

path: include/linux/mmzone.h
```
static inline int populated_zone(struct zone *zone)
{
    return (!!zone->present_pages);
}
```
