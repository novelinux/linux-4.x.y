map_lowmem
========================================

map_lowmem函数的作用就是映射lowmem区间，该区间的映射用到L1页表:

### aries

```
[    0.000000]     lowmem  : 0xc0000000 - 0xef800000   ( 760 MB)
```

memblock
----------------------------------------

path: arch/arm/mm/mmu.c
```
static void __init map_lowmem(void)
{
    struct memblock_region *reg;
    /* 1.计算kernel的起始物理地址 */
    unsigned long kernel_x_start = round_down(__pa(_stext), SECTION_SIZE);
    /* 2.计算__init_end的物理地址 */
    unsigned long kernel_x_end = round_up(__pa(__init_end), SECTION_SIZE);

    /* Map all the lowmem memory banks. */
    for_each_memblock(memory, reg) {
        phys_addr_t start = reg->base;
        phys_addr_t end = start + reg->size;
        struct map_desc map;

    printk(KERN_CRIT "liminghao: %s(%llx~%llx)\n",
           __FUNCTION__,
           (unsigned long long)start,
           (unsigned long long)end);

    printk(KERN_CRIT "liminghao: %s(%llx~%llx)\n",
           __FUNCTION__,
           (unsigned long long)__phys_to_virt(start),
           (unsigned long long)__phys_to_virt(end));
```

在memblock机制应用中有提到，系统中所有的内存块都在启动时被注册到memblock中以
struct memblock_region的形式存在。map_lowmem的作用就是将以struct memblock_region类型的
内存节点转换为struct map_desc类型然后传递给create_mapping。

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/memblock.c/memblock.md

### dmesg

在上述代码段添加如下log信息打印如下所示:

```
[    0.000000] liminghao: map_lowmem(80200000~88e00000)
[    0.000000] liminghao: map_lowmem(c0000000~c8c00000)

[    0.000000] liminghao: map_lowmem(89000000~8da00000)
[    0.000000] liminghao: map_lowmem(c8e00000~cd800000)

[    0.000000] liminghao: map_lowmem(8ec00000~8f000000)
[    0.000000] liminghao: map_lowmem(cea00000~cee00000)

[    0.000000] liminghao: map_lowmem(8f700000~8fe00000)
[    0.000000] liminghao: map_lowmem(cf500000~cfc00000)

[    0.000000] liminghao: map_lowmem(8ff00000~9fe00000)
[    0.000000] liminghao: map_lowmem(cfd00000~dfc00000)

[    0.000000] liminghao: map_lowmem(a0000000~a5800000)
[    0.000000] liminghao: map_lowmem(dfe00000~e5600000)

[    0.000000] liminghao: map_lowmem(a5900000~afa00000)
[    0.000000] liminghao: map_lowmem(e5700000~ef800000)
```

create_mapping
----------------------------------------

```
        if (end > arm_lowmem_limit)
            end = arm_lowmem_limit;
        if (start >= end)
            break;

        if (end < kernel_x_start) {
            map.pfn = __phys_to_pfn(start);
            map.virtual = __phys_to_virt(start);
            map.length = end - start;
            map.type = MT_MEMORY_RWX;

            create_mapping(&map);
        } else if (start >= kernel_x_end) {
            map.pfn = __phys_to_pfn(start);
            map.virtual = __phys_to_virt(start);
            map.length = end - start;
            map.type = MT_MEMORY_RW;

            create_mapping(&map);
        } else {
            /* This better cover the entire kernel */
            if (start < kernel_x_start) {
                map.pfn = __phys_to_pfn(start);
                map.virtual = __phys_to_virt(start);
                map.length = kernel_x_start - start;
                map.type = MT_MEMORY_RW;

                create_mapping(&map);
            }

            map.pfn = __phys_to_pfn(kernel_x_start);
            map.virtual = __phys_to_virt(kernel_x_start);
            map.length = kernel_x_end - kernel_x_start;
            map.type = MT_MEMORY_RWX;

            create_mapping(&map);

            if (kernel_x_end < end) {
                map.pfn = __phys_to_pfn(kernel_x_end);
                map.virtual = __phys_to_virt(kernel_x_end);
                map.length = end - kernel_x_end;
                map.type = MT_MEMORY_RW;

                create_mapping(&map);
            }
        }
    }
}
```

### __phys_to_pfn

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/memory.h/__phys_to_pfn.md

### __phys_to_virt

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/memory.h/__pa_vs__va.md

### create_mapping

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/create_mapping.md
