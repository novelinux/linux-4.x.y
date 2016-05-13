struct memblock
========================================

path: include/linux/memblock.h
```
struct memblock {
```

bottom_up
----------------------------------------

```
    bool bottom_up;  /* is bottom up direction? */
```

表示分配器分配内存的方式:

* true - 从低地址(内核映像的尾部)向高地址分配;
* false - 也就是top-down,从高地址向地址分配内存.

current_limit
----------------------------------------

```
    phys_addr_t current_limit;
```

用于限制通过memblock_alloc的内存申请.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/memblock.h/current_limit.md

memory
----------------------------------------

```
    struct memblock_type memory;
```

是可用内存的集合.

reserved
----------------------------------------

```
    struct memblock_type reserved;
#ifdef CONFIG_HAVE_MEMBLOCK_PHYS_MAP
    struct memblock_type physmem;
#endif
};
```

已分配内存的集合.

struct memblock_type
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/memblock.h/struct_memblock_type.md