early_alloc
========================================

path: arch/arm/mm/mmu.c
```
static void __init *early_alloc_aligned(unsigned long sz, unsigned long align)
{
    void *ptr = __va(memblock_alloc(sz, align));
    memset(ptr, 0, sz);
    return ptr;
}

static void __init *early_alloc(unsigned long sz)
{
    return early_alloc_aligned(sz, sz);
}
```

memblock_alloc
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/memblock.c/memblock_alloc.md
