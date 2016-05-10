for_each_memblock
========================================

path: include/linux/memblock.h
```
#define for_each_memblock(memblock_type, region)                    \
    for (region = memblock.memblock_type.regions;                \
         region < (memblock.memblock_type.regions + memblock.memblock_type.cnt);    \
         region++)
```
