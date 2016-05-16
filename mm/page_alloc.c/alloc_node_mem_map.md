alloc_node_mem_map
========================================

alloc_node_mem_map负责初始化一个简单但非常重要的数据结构。如上所述，系统中的各个物理内存页，
都对应着一个struct page实例。该结构的初始化由alloc_node_mem_map执行

path: mm/page_alloc.c
```
static void __init_refok alloc_node_mem_map(struct pglist_data *pgdat)
{
    /* Skip empty nodes */
    // 没有页的空结点显然可以跳过。
    if (!pgdat->node_spanned_pages)
        return;

#ifdef CONFIG_FLAT_NODE_MEM_MAP
    /* ia64 gets its own node_mem_map, before this, without bootmem */
    /* 如果特定于体系结构的代码尚未建立内存映射（这是可能的，例如，在IA-64系统上），则必须分配与
     * 该结点关联的所有struct page实例所需的内存。各个体系结构可以为此提供一个特定的函数。但目前
     * 只有在IA-32系统上使用不连续内存配置时是这样。在所有其他的配置上，则使用普通的自举内存
     * 分配器进行分配。请注意，代码将内存映射对齐到伙伴系统的最大分配阶，因为要使所有的计算
     * 都工作正常，这是必需的。
     */
    if (!pgdat->node_mem_map) {
        unsigned long size, start, end;
        struct page *map;

        /*
         * The zone's endpoints aren't required to be MAX_ORDER
         * aligned but the node_mem_map endpoints must be in order
         * for the buddy allocator to function correctly.
         */
        start = pgdat->node_start_pfn & ~(MAX_ORDER_NR_PAGES - 1);
        end = pgdat_end_pfn(pgdat);
        end = ALIGN(end, MAX_ORDER_NR_PAGES);
        size =  (end - start) * sizeof(struct page);
        map = alloc_remap(pgdat->node_id, size);
        if (!map)
            map = memblock_virt_alloc_node_nopanic(size,
                                   pgdat->node_id);
        pgdat->node_mem_map = map + (pgdat->node_start_pfn - start);
    }
```

mem_map
----------------------------------------

指向该空间的指针不仅保存在pglist_data实例中，还保存在全局变量mem_map中，前提是当前考察的结点是
系统的第0个结点（如果系统只有一个内存结点，则总是这样）。mem_map是一个全局数组.

```
#ifndef CONFIG_NEED_MULTIPLE_NODES
    /*
     * With no DISCONTIG, the global mem_map is just set as node 0's
     */
    if (pgdat == NODE_DATA(0)) {
        mem_map = NODE_DATA(0)->node_mem_map;
#ifdef CONFIG_HAVE_MEMBLOCK_NODE_MAP
        if (page_to_pfn(mem_map) != pgdat->node_start_pfn)
            mem_map -= (pgdat->node_start_pfn - ARCH_PFN_OFFSET);
#endif /* CONFIG_HAVE_MEMBLOCK_NODE_MAP */
    }
#endif
#endif /* CONFIG_FLAT_NODE_MEM_MAP */
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/memory.c/mem_map.md

aries
----------------------------------------

```
CONFIG_FLAT_NODE_MEM_MAP=y
```