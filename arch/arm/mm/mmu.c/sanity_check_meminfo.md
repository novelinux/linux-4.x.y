sanity_check_meminfo
========================================

在通过arm_memblock_init函数通过memblock算法初始化了内核初始化阶段的物理内存分配器:

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/init.c/arm_memblock_init.md

初始化完成之后可用物理内存region如下所示:

```
[    0.000000]  memory size = 0x7d1ff000 reserved size = 0x8b33cf1
[    0.000000]  memory.cnt  = 0x7
[    0.000000]  memory[0x0]     [0x00000080200000-0x00000088dfffff], 0x8c00000 bytes
[    0.000000]  memory[0x1]     [0x00000089000000-0x0000008d9fffff], 0x4a00000 bytes
[    0.000000]  memory[0x2]     [0x0000008ec00000-0x0000008effffff], 0x400000 bytes
[    0.000000]  memory[0x3]     [0x0000008f700000-0x0000008fdfffff], 0x700000 bytes
[    0.000000]  memory[0x4]     [0x0000008ff00000-0x0000009fdfffff], 0xff00000 bytes
[    0.000000]  memory[0x5]     [0x000000a0000000-0x000000a57fffff], 0x5800000 bytes
[    0.000000]  memory[0x6]     [0x000000a5900000-0x000000ff2fefff], 0x599ff000 bytes
```

接下来调用sanity_check_meminfo用于检查meminfo注册的内存region的有效性，比如大小，是否重叠等，
检测错误的内存region将被从meminfo中移除。

vmalloc_min
----------------------------------------

path: arch/arm/mm/mmu.c
```
static void * __initdata vmalloc_min =
    (void *)(VMALLOC_END - (240 << 20) - VMALLOC_OFFSET);

phys_addr_t arm_lowmem_limit __initdata = 0;

void __init sanity_check_meminfo(void)
{
    phys_addr_t memblock_limit = 0;
    int highmem = 0;
    phys_addr_t vmalloc_limit = __pa(vmalloc_min - 1) + 1;
```

### aries dmesg

```
vmalloc_min=ef800000
```

for_each_memblock
----------------------------------------

```
    struct memblock_region *reg;

    /* 逐个扫描可用物理内存region */
    for_each_memblock(memory, reg) {
```

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/memblock.h/for_each_memblock.md

计算high_memory
----------------------------------------

```
        phys_addr_t block_start = reg->base;
        phys_addr_t block_end = reg->base + reg->size;
        phys_addr_t size_limit = reg->size;

        if (reg->base >= vmalloc_limit)
            highmem = 1;
        else
            size_limit = vmalloc_limit - reg->base;

        /* 检查是否支持高端内存, 不支持执行如下代码 */
        if (!IS_ENABLED(CONFIG_HIGHMEM) || cache_is_vipt_aliasing()) {

            if (highmem) {
                pr_notice("Ignoring RAM at %pa-%pa (!CONFIG_HIGHMEM)\n",
                      &block_start, &block_end);
                memblock_remove(reg->base, reg->size);
                continue;
            }

            if (reg->size > size_limit) {
                phys_addr_t overlap_size = reg->size - size_limit;

                pr_notice("Truncating RAM at %pa-%pa to -%pa",
                      &block_start, &block_end, &vmalloc_limit);
                memblock_remove(vmalloc_limit, overlap_size);
                block_end = vmalloc_limit;
            }
        }

        if (!highmem) {
            if (block_end > arm_lowmem_limit) {
                if (reg->size > size_limit)
                    arm_lowmem_limit = vmalloc_limit;
                else
                    arm_lowmem_limit = block_end;
            }

            /*
             * Find the first non-section-aligned page, and point
             * memblock_limit at it. This relies on rounding the
             * limit down to be section-aligned, which happens at
             * the end of this function.
             *
             * With this algorithm, the start or end of almost any
             * bank can be non-section-aligned. The only exception
             * is that the start of the bank 0 must be section-
             * aligned, since otherwise memory would need to be
             * allocated when mapping the start of bank 0, which
             * occurs before any free memory is mapped.
             */
            if (!memblock_limit) {
                if (!IS_ALIGNED(block_start, SECTION_SIZE))
                    memblock_limit = block_start;
                else if (!IS_ALIGNED(block_end, SECTION_SIZE))
                    memblock_limit = arm_lowmem_limit;
            }

        }
    }

    high_memory = __va(arm_lowmem_limit - 1) + 1;

    /*
     * Round the memblock limit down to a section size.  This
     * helps to ensure that we will allocate memory from the
     * last full section, which should be mapped.
     */
    if (memblock_limit)
        memblock_limit = round_down(memblock_limit, SECTION_SIZE);
    if (!memblock_limit)
        memblock_limit = arm_lowmem_limit;
```

### aries

```
arm_lowmem_limit=afa00000
__va(arm_lowmem_limit)=ef800000
high_memory=ef800000
```

memblock_set_current_limit
----------------------------------------

```
    memblock_set_current_limit(memblock_limit);
}
```

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/mm/memblock.c/memblock_set_current_limit.md

### aries

```
memblock_limit=afa00000
```

high_memory vs low_memory
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/mm/misc/high_memory-low_memory.md
