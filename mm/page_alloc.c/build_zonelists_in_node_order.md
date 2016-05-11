build_zonelists_in_node_order
========================================

把node节点上的内存域排列到pgdat->zonelists中.

path: mm/page_alloc.c
```
/*
 * Build zonelists ordered by node and zones within node.
 * This results in maximum locality--normal zone overflows into local
 * DMA zone, if any--but risks exhausting DMA zone.
 */
static void build_zonelists_in_node_order(pg_data_t *pgdat, int node)
{
    int j;
    struct zonelist *zonelist;

    zonelist = &pgdat->node_zonelists[0];
    for (j = 0; zonelist->_zonerefs[j].zone != NULL; j++)
        ;
    j = build_zonelists_node(NODE_DATA(node), zonelist, j);
    // 结束标识，为下次再调用该函数上面for循环使用，会紧接着本次结束位置开始.
    zonelist->_zonerefs[j].zone = NULL;
    zonelist->_zonerefs[j].zone_idx = 0;
}
```

build_zonelists_node
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/build_zonelists_node.md
