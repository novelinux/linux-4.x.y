paging_init
========================================

paging_init初始化内核页表并启用内存分页, 在那linux刚启动时，系统创建了一个临时页表:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head.S/__create_page_tables.md

paging_init负责建立只能用于内核的页表，用户空间无法访问。这对管理普通应用程序和内核访问内存的
方式，有深远的影响。

Code Flow
----------------------------------------

```
paging_init
    |
    +--> build_mem_type_table
    |
    +--> prepare_page_table
    |
    +--> map_lowmem
    |
    +--> dma_contiguous_remap
    |
    +--> devicemaps_init
    |
    +--> kmap_init
    |
    +--> tcm_init
    |
    +--> bootmem_init
```

build_mem_type_table
----------------------------------------

build_mem_type_table主要是用来建立各种类型的页表选项(比如内存是MEMORY类型，设备是DEVICE，
中断向量表是HIGH_VECTORS)。

path: arch/arm/mm/mmu.c
```
/*
 * paging_init() sets up the page tables, initialises the zone memory
 * maps, and sets up the zero page, bad page and bad page tables.
 */
void __init paging_init(const struct machine_desc *mdesc)
{
    void *zero_page;

    build_mem_type_table();
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c/build_mem_type_table.md

prepare_page_table
----------------------------------------

prepare_page_table则用于初始化页表.

```
    prepare_page_table();
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c/prepare_page_table.md

map_lowmem
----------------------------------------

map_lowmem()是为低端物理内存建立映.

```
    map_lowmem();
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c/map_lowmem.md

dma_contiguous_remap
----------------------------------------

```
    dma_contiguous_remap();
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/dma-mapping.c/dma_contiguous_remap.md

devicemaps_init
----------------------------------------

```
    devicemaps_init(mdesc);
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c/devicemaps_init.md

kmap_init
----------------------------------------

```
    kmap_init();
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c/kmap_init.md

tcm_init
----------------------------------------

空函数

```
    tcm_init();
```

bootmem_init
----------------------------------------

```
    top_pmd = pmd_off_k(0xffff0000);

    /* allocate the zero page. */
    zero_page = early_alloc(PAGE_SIZE);

    bootmem_init();

    empty_zero_page = virt_to_page(zero_page);
    __flush_dcache_page(NULL, empty_zero_page);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/init.c/bootmem_init.md

注意
----------------------------------------

函数paging_init，实际上取名不当。它并不初始化分页机制，只是处理一些稀疏内存系统的设置例程，
但重要的是该函数还调用了free_area_init_nodes，其负责初始化内核管理物理页帧的数据结构。