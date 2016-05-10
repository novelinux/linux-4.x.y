memblock_allow_resize
========================================

path: mm/memblock.c
```
static int memblock_can_resize __initdata_memblock;

...

void __init memblock_allow_resize(void)
{
    memblock_can_resize = 1;
}
```