VMALLOC
========================================

path: arch/arm/include/asm/pgtable.h
```
/*
 * Just any arbitrary offset to the start of the vmalloc VM area: the
 * current 8MB value just means that there will be a 8MB "hole" after the
 * physical memory until the kernel virtual memory starts.  That means that
 * any out-of-bounds memory accesses will hopefully be caught.
 * The vmalloc() routines leaves a hole of 4kB between each vmalloced
 * area for the same reason. ;)
 */
#define VMALLOC_OFFSET (8*1024*1024)
#define VMALLOC_START  (((unsigned long)high_memory + VMALLOC_OFFSET) & ~(VMALLOC_OFFSET-1))
#define VMALLOC_END    0xff000000UL
```

* VMALLOC_START vs VMALLOC_END

VMALLOC_START和VMALLOC_END定义了vmalloc区域的开始和结束，该区域用于物理上不连续的内核映射。
这两个值没有直接定义为常数，而是依赖于几个参数。vmalloc区域的起始地址，取决于在直接映射物理
内存时，使用了多少虚拟地址空间内存（因此也依赖于high_memory变量）。内核还考虑到下述事实，
即两个区域之间有至少为VMALLOC_OFFSET的一个缺口.

* VMALLOC_OFFSET

定义了8M的空洞，用于捕捉越界的内存访问。如果VMALLOC_OFFSET取最小值，那么在
lowmem和vmalloc区域之间，会出现一个缺口。这个缺口可用作针对任何内核故障的保护措施。如果访问
越界地址（即无意地访问物理上不存在的内存区），则访问失败并生成一个异常，报告该错误。如果vmalloc
区域紧接着直接映射，那么访问将成功而不会注意到错误。在稳定运行的情况下，肯定不需要这个额外的
保护措施，但它对开发尚未成熟的新内核特性是有用的。

high_memory
----------------------------------------

### 定义

https://github.com/novelinux/linux-4.x.y/tree/master/mm/memory.c/high_memory.md

### 初始化

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c/sanity_check_meminfo.md
