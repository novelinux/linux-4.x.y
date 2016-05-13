struct memblock_region
========================================

path: include/linux/memblock.h
```
struct memblock_region {
```

base
----------------------------------------

内存区域起始地址.

```
    phys_addr_t base;
```

size
----------------------------------------

内存区域大小.

```
    phys_addr_t size;
```

flags
----------------------------------------

标记.

```
    unsigned long flags;
```

nid
----------------------------------------

node号.

```
#ifdef CONFIG_HAVE_MEMBLOCK_NODE_MAP
    int nid;
#endif
};
```
