memblock_start_of_DRAM
========================================

path: mm/memblock.c
```
/* lowest address */
phys_addr_t __init_memblock memblock_start_of_DRAM(void)
{
    return memblock.memory.regions[0].base;
}
```

memblock
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/memblock.c/memblock.md
