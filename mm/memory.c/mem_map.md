mem_map
========================================

path: mm/memory.c
```
#ifndef CONFIG_NEED_MULTIPLE_NODES
/* use the per-pgdat data instead for discontigmem - mbligh */
unsigned long max_mapnr;
struct page *mem_map;

EXPORT_SYMBOL(max_mapnr);
EXPORT_SYMBOL(mem_map);
#endif
```

alloc_node_mem_map
----------------------------------------

mem_map的初始化是在alloc_node_mem_map函数中实现的.

https://github.com/novelinux/linux-4.x.y/blob/master/mm/page_alloc.c/alloc_node_mem_map.md