build_zonelists_in_node_order
========================================

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
    /* 这里循环迭代大于当前结点编号的所有结点。新的项通过build_zonelists_in_node_order
     * 添加到备用列表。此时的j的作用就体现出来了。在本地结点的备用目标找到之后，该变量值改变。
     * 该值作为新项的起始地址。
     */
    for (j = 0; zonelist->_zonerefs[j].zone != NULL; j++)
        ;
    j = build_zonelists_node(NODE_DATA(node), zonelist, j);
    zonelist->_zonerefs[j].zone = NULL;
    zonelist->_zonerefs[j].zone_idx = 0;
}
```

这里对所有的编号小于当前结点的结点生成备用列表项。备用列表项中的数目一般无法准确知道，因为
系统中不同结点的内存域配置可能并不相同。因此列表的最后一项赋值为空指针，显示标记列表结束。

build_zonelists_node
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/page_alloc.c/build_zonelists_node.md
