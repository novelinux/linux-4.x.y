build_zonelists_in_zone_order
========================================

path: mm/page_alloc.c
```
/*
 * Build zonelists ordered by zone and nodes within zones.
 * This results in conserving DMA zone[s] until all Normal memory is
 * exhausted, but results in overflowing to remote node while memory
 * may still exist in local DMA zone.
 */
static int node_order[MAX_NUMNODES];

static void build_zonelists_in_zone_order(pg_data_t *pgdat, int nr_nodes)
{
    int pos, j, node;
    int zone_type;        /* needs to be signed */
    struct zone *z;
    struct zonelist *zonelist;

    zonelist = &pgdat->node_zonelists[0];
    pos = 0;
    for (zone_type = MAX_NR_ZONES - 1; zone_type >= 0; zone_type--) {
        for (j = 0; j < nr_nodes; j++) {
            node = node_order[j];
            z = &NODE_DATA(node)->node_zones[zone_type];
            if (populated_zone(z)) {
                zoneref_set_zone(z,
                    &zonelist->_zonerefs[pos++]);
                check_highest_zone(zone_type);
            }
        }
    }
    zonelist->_zonerefs[pos].zone = NULL;
    zonelist->_zonerefs[pos].zone_idx = 0;
}
```

### enum zone_type

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/enum_zone_type.md

### populated_zone

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/populated_zone.md

### zoneref_set_zone

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/zoneref_set_zone.md
