wakeup_kswapd
========================================

path: mm/vmscan.c
```
/*
 * A zone is low on free memory, so wake its kswapd task to service it.
 */
void wakeup_kswapd(struct zone *zone, int order, enum zone_type classzone_idx)
{
    pg_data_t *pgdat;

    if (!populated_zone(zone))
        return;

    if (!cpuset_zone_allowed(zone, GFP_KERNEL | __GFP_HARDWALL))
        return;
    pgdat = zone->zone_pgdat;
    if (pgdat->kswapd_max_order < order) {
        pgdat->kswapd_max_order = order;
        pgdat->classzone_idx = min(pgdat->classzone_idx, classzone_idx);
    }
    if (!waitqueue_active(&pgdat->kswapd_wait))
        return;
    if (zone_balanced(zone, order, 0, 0))
        return;

    trace_mm_vmscan_wakeup_kswapd(pgdat->node_id, zone_idx(zone), order);
    wake_up_interruptible(&pgdat->kswapd_wait);
}
```
