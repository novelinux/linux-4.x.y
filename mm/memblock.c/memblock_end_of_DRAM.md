memblock_end_of_DRAM
========================================

path: mm/memblock.c
```
phys_addr_t __init_memblock memblock_end_of_DRAM(void)
{
    int idx = memblock.memory.cnt - 1;

    return (memblock.memory.regions[idx].base + memblock.memory.regions[idx].size);
}
```

memblock
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/memblock.c/memblock.md