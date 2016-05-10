Virtual kernel memory layout
========================================

kmsg
----------------------------------------

```
[    0.000000] Memory: 140MB 74MB 4MB 7MB 255MB 88MB 1433MB = 2001MB total
[    0.000000] Memory: 1859388k/1859388k available, 207040k reserved, 1297404K highmem
[    0.000000] Virtual kernel memory layout:
[    0.000000]     vector  : 0xffff0000 - 0xffff1000   (   4 kB)
[    0.000000]     timers  : 0xfffef000 - 0xffff0000   (   4 kB)
[    0.000000]     fixmap  : 0xfff00000 - 0xfffe0000   ( 896 kB)
[    0.000000]     vmalloc : 0xf0000000 - 0xff000000   ( 240 MB)
[    0.000000]     lowmem  : 0xc0000000 - 0xef800000   ( 760 MB)
[    0.000000]     pkmap   : 0xbfe00000 - 0xc0000000   (   2 MB)
[    0.000000]     modules : 0xbf000000 - 0xbfe00000   (  14 MB)
[    0.000000]       .text : 0xc0008000 - 0xc0e07f80   (14336 kB)
[    0.000000]       .init : 0xc0f00000 - 0xc101df40   (1144 kB)
[    0.000000]       .data : 0xc101e000 - 0xc121aac0   (2035 kB)
[    0.000000]        .bss : 0xc121aae4 - 0xc1a4e2e4   (8398 kB)
```

* lowmem
 0xc0000000 ~ 0xef800000映射lowmem(低端内存，即zone[Normal])。这段映射是一对一的平坦映射，也就是
 说kernel初始化这段映射后，页表将不会改变。这样即可以省去不断的修改页表，刷新TLB（TLB可以认为是
 页表的硬件cache，如果访问的虚拟地址的页表在这个cache中，则CPU无需访问DDR寻址页表了，这样可以
 提高IO效率）了。显然这段地址空间非常珍贵，因为这段映射的效率高。

* vmalloc
 0xef800000 ~ 0xff000000映射highmem（高端内存，即zone[HighMem]）。大于1GB DDR，因此需要高端内存
 映射部分物理地址空间。

table
----------------------------------------

```
|--------------------------------------| 0xffffffff (4G)
|
|--------------------------------------| 0xff000000 <-- VMALLOC_END
|
|--------------------------------------| (high_memory + VMALLOC_OFFSET(8MB)) <-- VMALLOC_START
|
|--------------------------------------| 0xef000000 <--(high_memory arm_lowmem_limit)
|
|--------------------------------------| 0xc0000000 (3G) <-- PAGE_OFFSET
|
|--------------------------------------| (PAGE_OFFSET - PMD_SIZE(2MB)) <-- MODULES_END
|
|--------------------------------------| (PAGE_OFFSET - SZ_16M) <-- MODULES_VADDR
|
|--------------------------------------| 0x00000000 (0)
```

几个重要的宏定义
----------------------------------------

* PMD_SIZE

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/pgtable-2level.h/PMD_XXX.md

* MODULES_VADDR

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory.h/MODULES_VADDR.md

* PAGE_OFFSET

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory.h/PAGE_OFFSET.md

* VMALLOC_START

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/pgtable.h/VMALLOC.md