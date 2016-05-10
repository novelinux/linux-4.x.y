struct memblock_region
========================================

path: include/linux/memblock.h
```
struct memblock_region {
    phys_addr_t base;
    phys_addr_t size;
    unsigned long flags;
#ifdef CONFIG_HAVE_MEMBLOCK_NODE_MAP
    int nid;
#endif
};
```

* base: 内存区域起始地址.

* size: 内存区域大小.

* flags: 标记.

* nid: node号.
