memblock_set_current_limit
========================================

path: mm/memblock.c
```
void __init_memblock memblock_set_current_limit(phys_addr_t limit)
{
        memblock.current_limit = limit;
}
```
