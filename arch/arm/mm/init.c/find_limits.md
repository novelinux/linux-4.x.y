find_limits
========================================

path: arch/arm/mm/init.c
```
static void __init find_limits(unsigned long *min, unsigned long *max_low,
                   unsigned long *max_high)
{
    *max_low = PFN_DOWN(memblock_get_current_limit());
    *min = PFN_UP(memblock_start_of_DRAM());
    *max_high = PFN_DOWN(memblock_end_of_DRAM());
}
```

### aries

```
min=80200, max_low=afa00, max_high=fffff
```

memblock_get_current_limit
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/mm/memblock.c/memblock_get_current_limit.md

memblock.current_limit值是在如下调用过程中设置的:

```
setup_arch --> sanity_check_meminfo --> memblock_set_current_limit
```

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/kernel/setup.c/setup_arch.md

memblock_start_of_DRAM
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/mm/memblock.c/memblock_start_of_DRAM.md

memblock_end_of_DRAM
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/mm/memblock.c/memblock_end_of_DRAM.md

PFN_XXX
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/pfn.h/PFN_XXX.md
