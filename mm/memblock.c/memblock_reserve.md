memblock_reserve
========================================

path: mm/memblock.c
```
int __init_memblock memblock_reserve(phys_addr_t base, phys_addr_t size)
{
    return memblock_reserve_region(base, size, MAX_NUMNODES, 0);
}
```

memblock_reserve_region
----------------------------------------

path: mm/memblock.c
```
static int __init_memblock memblock_reserve_region(phys_addr_t base,
                           phys_addr_t size,
                           int nid,
                           unsigned long flags)
{
    struct memblock_type *_rgn = &memblock.reserved;

    memblock_dbg("memblock_reserve: [%#016llx-%#016llx] flags %#02lx %pF\n",
             (unsigned long long)base,
             (unsigned long long)base + size - 1,
             flags, (void *)_RET_IP_);

    return memblock_add_range(_rgn, base, size, nid, flags);
}
```

memblock_add_range
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/memblock.c/memblock_add_range.md
