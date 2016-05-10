build_zonelists
========================================

Arguments
----------------------------------------

建立备用层次结构的任务委托给build_zonelists，该函数为每个NUMA结点都创建了相应的数据结构。
build_zonelists需要一个指向pgdat_t实例的指针作为参数，其中包含了结点内存配置的所有现存信息，
而新建的数据结构也会放置在其中。

path: mm/page_alloc.c
```
static void build_zonelists(pg_data_t *pgdat)
{
    int j, node, load;
    enum zone_type i;
    nodemask_t used_mask;
    int local_node, prev_node;
    struct zonelist *zonelist;
```

current_zonelist_order
----------------------------------------

current_zonelist_order指定当前zonelist的顺序，由函数set_zonelist_order设置.

```
    int order = current_zonelist_order;
```

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/page_alloc.c/current_zonelist_order.md

node_zonelists
----------------------------------------

内核使用pg_data_t中的zonelist数组，来表示所描述的层次结构。node_zonelists数组对每种可能的内存域
类型，都配置了一个独立的数组项。数组项包含了类型为zonelist的一个备用列表.由于该备用列表必须包括
所有结点的所有内存域，因此由MAX_NUMNODES * MAX_NZ_ZONES项组成，外加一个用于标记列表结束的空指针。

```
    /* initialize zonelists */
    for (i = 0; i < MAX_ZONELISTS; i++) {
        zonelist = pgdat->node_zonelists + i;
        zonelist->_zonerefs[0].zone = NULL;
        zonelist->_zonerefs[0].zone_idx = 0;
    }
```

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/mmzone.h/pg_data_t.md

nodes_clear
----------------------------------------

```
    /* NUMA-aware ordering of nodes */
    local_node = pgdat->node_id;
    load = nr_online_nodes;
    prev_node = local_node;
    nodes_clear(used_mask);
```

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/nodemask.h/nodes_clear.md

node_order
----------------------------------------

```
    memset(node_order, 0, sizeof(node_order));
```

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/page_alloc.c/nodes_order.md

build_zonelists_in_node_order
----------------------------------------

```
    j = 0;

    while ((node = find_next_best_node(local_node, &used_mask)) >= 0) {
        /*
         * We don't want to pressure a particular node.
         * So adding penalty to the first node in same
         * distance group to make it round-robin.
         */
        if (node_distance(local_node, node) !=
            node_distance(local_node, prev_node))
            node_load[node] = load;

        prev_node = node;
        load--;

        if (order == ZONELIST_ORDER_NODE)
            build_zonelists_in_node_order(pgdat, node);
        else
            node_order[j++] = node;    /* remember order */
    }
```

### find_next_best_node

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/page_alloc.c/find_next_best_node.md

### node_distance

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/topology.h/node_distance.md

### buile_zonelist_in_node_order

实际工作则委托给buile_zonelist_in_node_order在调用时，它首先生成本地结点内分配内存时的备用次序。

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/page_alloc.c/build_zonelists_in_node_order.md

build_zonelists_in_zone_order
----------------------------------------

```
    if (order == ZONELIST_ORDER_ZONE) {
        /* calculate node order -- i.e., DMA last! */
        build_zonelists_in_zone_order(pgdat, j);
    }
```

build_thisnode_zonelists
----------------------------------------

```
    build_thisnode_zonelists(pgdat);
}
```