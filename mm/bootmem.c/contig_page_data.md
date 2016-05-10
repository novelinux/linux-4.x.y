contig_page_data
========================================

path: mm/bootmem.c
```
#ifndef CONFIG_NEED_MULTIPLE_NODES
struct pglist_data __refdata contig_page_data = {
    .bdata = &bootmem_node_data[0]
};
EXPORT_SYMBOL(contig_page_data);
#endif

...

bootmem_data_t bootmem_node_data[MAX_NUMNODES] __initdata;
```

struct pglist_data
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/include/linux/mmzone.h/pg_data_t.md

bootmem_data_t
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/bootmem.h/bootmem_data_t.md
