NODE_DATA
========================================

path: include/linux/mmzone.h
```
#ifndef CONFIG_NEED_MULTIPLE_NODES

extern struct pglist_data contig_page_data;
#define NODE_DATA(nid)        (&contig_page_data)
#define NODE_MEM_MAP(nid)     mem_map

#else /* CONFIG_NEED_MULTIPLE_NODES */

#include <asm/mmzone.h>

#endif /* !CONFIG_NEED_MULTIPLE_NODES */
```

contig_page_data
----------------------------------------

### CONFIG_NO_BOOTMEM is not set

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/mm/bootmem.c/contig_page_data.md

### CONFIG_NO_BOOTMEM=y
