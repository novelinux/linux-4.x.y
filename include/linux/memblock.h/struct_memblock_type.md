struct memblock_type
========================================

path: include/linux/memblock.h
```
struct memblock_type {
```

cnt
----------------------------------------

```
    unsigned long cnt;    /* number of regions */
```

当前集合(memory或者reserved)中记录的内存区域个数.

max
----------------------------------------

```
    unsigned long max;    /* size of the allocated array */
```

当前集合(memory或者reserved)中可记录的内存区域的最大个数, max的值可以是:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/memblock.h/max.md

total_size
----------------------------------------

```
    phys_addr_t total_size;    /* size of all regions */
```

集合记录区域信息大小.

regions
----------------------------------------

```
    struct memblock_region *regions;
};
```

内存区域结构指针.

struct memblock_region
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/memblock.h/struct_memblock_region.md
