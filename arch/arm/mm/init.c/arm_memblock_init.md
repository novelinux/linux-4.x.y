arm_memblock_init
========================================

memblock算法是linux内核初始化阶段的一个内存分配器,本质上是取代了原来的bootmem算法.
memblock实现比较简单,而它的作用就是在page allocator初始化之前来管理内存,完成分配和释放请求.

memblock_reserve - kernel
----------------------------------------

path: arch/arm/mm/init.c
```
void __init arm_memblock_init(const struct machine_desc *mdesc)
{
    /* Register the kernel text, kernel data and initrd with memblock. */
#ifdef CONFIG_XIP_KERNEL
    memblock_reserve(__pa(_sdata), _end - _sdata);
#else
    memblock_reserve(__pa(_stext), _end - _stext);
#endif
```

将kernel占用的内存空间添加到已分配内存集合reserved中

```
[    0.000000] memblock_reserve: [0x00000080300000-0x00000081c4e2e4] arm_memblock_init+0x68/0x1a0
```

通过查看/proc/iomem查看到kernel所占用的物理内存信息如下所示:

```
  80208000-81007f7f : Kernel code
  8121e000-81c4e2e3 : Kernel data
```

### __pa

__pa宏用于将虚拟地址转换为物理地址.

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory.h/__pa_vs__va.md

memblock_reserve - initrd
----------------------------------------

```
#ifdef CONFIG_BLK_DEV_INITRD
    /* FDT scan will populate initrd_start */
    if (initrd_start && !phys_initrd_size) {
        phys_initrd_start = __virt_to_phys(initrd_start);
        phys_initrd_size = initrd_end - initrd_start;
    }
    initrd_start = initrd_end = 0;
    if (phys_initrd_size &&
        !memblock_is_region_memory(phys_initrd_start, phys_initrd_size)) {
        pr_err("INITRD: 0x%08llx+0x%08lx is not a memory region - disabling initrd\n",
               (u64)phys_initrd_start, phys_initrd_size);
        phys_initrd_start = phys_initrd_size = 0;
    }
    if (phys_initrd_size &&
        memblock_is_region_reserved(phys_initrd_start, phys_initrd_size)) {
        pr_err("INITRD: 0x%08llx+0x%08lx overlaps in-use memory region - disabling initrd\n",
               (u64)phys_initrd_start, phys_initrd_size);
        phys_initrd_start = phys_initrd_size = 0;
    }
    if (phys_initrd_size) {
        memblock_reserve(phys_initrd_start, phys_initrd_size);

        /* Now convert initrd to virtual addresses */
        initrd_start = __phys_to_virt(phys_initrd_start);
        initrd_end = initrd_start + phys_initrd_size;
    }
#endif
```

将ramdisk(initrd)占用的物理内存空间添加到已分配内存集合reserved中:

```
[    0.000000] memblock_reserve: [0x00000082200000-0x000000823e1a0d] arm_memblock_init+0xe8/0x1a0
```

### aries

```
CONFIG_BLK_DEV_INITRD=y
```

memblock_reserve
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/memblock.c/memblock_reserve.md

arm_mm_memblock_reserve
----------------------------------------

```
    arm_mm_memblock_reserve();
```

mdesc->reserve
----------------------------------------

```
    /* reserve any platform specific memblock areas */
    if (mdesc->reserve)
        mdesc->reserve();

    early_init_fdt_scan_reserved_mem();

    /*
     * reserve memory for DMA contigouos allocations,
     * must come from DMA area inside low memory
     */
    dma_contiguous_reserve(arm_dma_limit);

    arm_memblock_steal_permitted = false;
```

memblock_dump_all
----------------------------------------

```
    memblock_dump_all();
}
```

### aries

```
[    0.000000] MEMBLOCK configuration:
[    0.000000]  memory size = 0x7d1ff000 reserved size = 0x8b33cf1
[    0.000000]  memory.cnt  = 0x7
[    0.000000]  memory[0x0]     [0x00000080200000-0x00000088dfffff], 0x8c00000 bytes
[    0.000000]  memory[0x1]     [0x00000089000000-0x0000008d9fffff], 0x4a00000 bytes
[    0.000000]  memory[0x2]     [0x0000008ec00000-0x0000008effffff], 0x400000 bytes
[    0.000000]  memory[0x3]     [0x0000008f700000-0x0000008fdfffff], 0x700000 bytes
[    0.000000]  memory[0x4]     [0x0000008ff00000-0x0000009fdfffff], 0xff00000 bytes
[    0.000000]  memory[0x5]     [0x000000a0000000-0x000000a57fffff], 0x5800000 bytes
[    0.000000]  memory[0x6]     [0x000000a5900000-0x000000ff2fefff], 0x599ff000 bytes
[    0.000000]  reserved.cnt  = 0x5
[    0.000000]  reserved[0x0]   [0x00000080204000-0x00000080207fff], 0x4000 bytes
[    0.000000]  reserved[0x1]   [0x00000080300000-0x00000081c4e2e3], 0x194e2e4 bytes
[    0.000000]  reserved[0x2]   [0x00000082200000-0x000000823e1a0c], 0x1e1a0d bytes
[    0.000000]  reserved[0x3]   [0x000000a0000000-0x000000a57fffff], 0x5800000 bytes
[    0.000000]  reserved[0x4]   [0x000000ae800000-0x000000afffffff], 0x1800000 bytes
```
