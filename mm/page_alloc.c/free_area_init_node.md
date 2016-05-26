free_area_init_node
========================================

zone_sizes_init函数在初始化完成Node 0的ZONE大小之后便调用free_area_init_node函数来继续初始化
Node的其余数据结构.

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/init.c/zone_sizes_init.md

Code Flow
----------------------------------------

```
free_area_init_node
  |
  +-> calculate_node_totalpages
  |
  +-> alloc_node_mem_map
  |
  +-> free_area_init_core
      |
      +-> zone_pcp_init
      |
      +-> mod_zone_page_state
      |
      +-> set_pageblock_order
      |
      +-> setup_usemap
      |
      +-> init_currently_empty_zone
      |
      +-> memmap_init
          |
          +-> memmap_init_zone
              |
              +-> __init_single_page
              |
              +-> set_pageblock_migratetype
```

Arguments
----------------------------------------

path: mm/page_alloc.c
```
void __paginginit free_area_init_node(int nid, unsigned long *zones_size,
        unsigned long node_start_pfn, unsigned long *zholes_size)
{
```

### aries

```
nid=0
zone_size[0]=194560 # Normal
zone_size[ZONE_HIGHMEM]=329215 # Highmem
node_start_pfn=80200
```

Init Node nid(pg_data_t)
----------------------------------------

```
    pg_data_t *pgdat = NODE_DATA(nid);
    unsigned long start_pfn = 0;
    unsigned long end_pfn = 0;

    /* pg_data_t should be reset to zero when it's allocated */
    WARN_ON(pgdat->nr_zones || pgdat->classzone_idx);

    reset_deferred_meminit(pgdat);
    pgdat->node_id = nid;
    pgdat->node_start_pfn = node_start_pfn;
#ifdef CONFIG_HAVE_MEMBLOCK_NODE_MAP
    get_pfn_range_for_nid(nid, &start_pfn, &end_pfn);
    pr_info("Initmem setup node %d [mem %#018Lx-%#018Lx]\n", nid,
        (u64)start_pfn << PAGE_SHIFT,
        end_pfn ? ((u64)end_pfn << PAGE_SHIFT) - 1 : 0);
#endif
```

calculate_node_totalpages
----------------------------------------

```
    calculate_node_totalpages(pgdat, start_pfn, end_pfn,
                  zones_size, zholes_size);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/calculate_node_totalpages.md

alloc_node_mem_map
----------------------------------------

```
    alloc_node_mem_map(pgdat);
#ifdef CONFIG_FLAT_NODE_MEM_MAP
    printk(KERN_DEBUG "free_area_init_node: node %d, pgdat %08lx, node_mem_map %08lx\n",
        nid, (unsigned long)pgdat,
        (unsigned long)pgdat->node_mem_map);
#endif
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/alloc_node_mem_map.md

free_area_init_core
----------------------------------------

```
    free_area_init_core(pgdat);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/free_area_init_core.md
