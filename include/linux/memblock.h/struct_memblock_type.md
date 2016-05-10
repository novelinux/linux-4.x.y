struct memblock_type
========================================

path: include/linux/memblock.h
```
struct memblock_type {
    unsigned long cnt;    /* number of regions */
    unsigned long max;    /* size of the allocated array */
    phys_addr_t total_size;    /* size of all regions */
    struct memblock_region *regions;
};
```

* cnt
  当前集合(memory或者reserved)中记录的内存区域个数.

* max
  当前集合(memory或者reserved)中可记录的内存区域的最大个数.

* total_size
  集合记录区域信息大小.

* regions
  内存区域结构指针.

struct memblock_region
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/memblock.h/struct_memblock_region.md
