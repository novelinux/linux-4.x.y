reset_node_managed_pages
========================================

path: mm/nobootmem.c
```
void reset_node_managed_pages(pg_data_t *pgdat)
{
    struct zone *z;

    for (z = pgdat->node_zones; z < pgdat->node_zones + MAX_NR_ZONES; z++)
        z->managed_pages = 0;
}
```
