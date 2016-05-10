zoneref_set_zone
========================================

path: mm/page_alloc.c
```
static void zoneref_set_zone(struct zone *zone, struct zoneref *zoneref)
{
    zoneref->zone = zone;
    zoneref->zone_idx = zone_idx(zone);
}
```