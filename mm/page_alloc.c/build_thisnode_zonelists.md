build_thisnode_zonelists
========================================

path: mm/page_alloc.c
```
/*
 * Build gfp_thisnode zonelists
 */
static void build_thisnode_zonelists(pg_data_t *pgdat)
{
    int j;
    struct zonelist *zonelist;

    zonelist = &pgdat->node_zonelists[1];
    j = build_zonelists_node(pgdat, zonelist, 0);
    zonelist->_zonerefs[j].zone = NULL;
    zonelist->_zonerefs[j].zone_idx = 0;
}
```

build_zonelists_node
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/build_zonelists_node.md
