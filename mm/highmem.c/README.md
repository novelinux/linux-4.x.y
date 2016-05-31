pkmap
========================================

尽管vmalloc函数族可用于从高端内存域向内核映射页帧（这些在内核空间中通常是无法直接看到的），
但这并不是这些函数的实际用途。重要的是强调以下事实：内核提供了其他函数用于将ZONE_HIGHMEM页帧
显式映射到内核空间，这些函数与vmalloc机制无关.

如果需要将高端页帧长期映射作为持久映射到内核地址空间中，必须使用kmap函数。需要映射的页用
指向page的指针指定，作为该函数的参数。该函数在有必要时创建一个映射（即，如果该页确实是高端页），
并返回数据的地址。

如果没有启用高端支持，该函数的任务就比较简单。在这种情况下，所有页都可以直接访问，因此只需要
返回页的地址，无需显式创建一个映射。

如果确实存在高端页，情况会比较复杂。类似于vmalloc，内核首先必须建立高端页和所映射到的地址之间
的关联。还必须在虚拟地址空间中分配一个区域以映射页帧，最后，内核必须记录该虚拟区域的哪些部分
在使用中，哪些仍然是空闲的。

Pkmap Layout
----------------------------------------

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/README.md

Data Structure
----------------------------------------

### pkmap_count

https://github.com/novelinux/linux-4.x.y/blob/master/mm/highmem.c/pkmap_count.md

### struct page_address_map

https://github.com/novelinux/linux-4.x.y/blob/master/mm/highmem.c/struct_page_address_map.md

### page_address_htable

https://github.com/novelinux/linux-4.x.y/blob/master/mm/highmem.c/page_address_htable.md

### mem_map

https://github.com/novelinux/linux-4.x.y/blob/master/mm/memory.c/mem_map.md

下图描述了上述数据结构之间的相互关系:

https://github.com/novelinux/linux-4.x.y/blob/master/mm/highmem.c/res/data-structure.jpg

Initialization
----------------------------------------

### ARM

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/mmu.c/kmap_init.md

APIS
----------------------------------------

### ARM

#### kmap

```
kmap
 |
 +-> page_address (!PageHighMem(page)) <-+
 |   |                                   |
 |   +-> lowmem_page_address             |
 |                                       |
 +-> kmap_high (PageHighMem(page)) ------1
     |
     2-> map_new_virtual
```

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/highmem.c/kmap.md

#### kmap_atomic

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/highmem.c/kmap_atomic.md

#### kunmap

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/highmem.c/kunmap.md
