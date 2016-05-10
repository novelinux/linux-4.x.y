VMALLOC.md
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

VMALLOC_START和VMALLOC_END分别定义了内核堆区的起始地址。VMALLOC_OFFSET定义了8M的空洞，用于捕捉
越界的内存访问。VMALLOC_START的值为high_memory + 8M。

high_memory
----------------------------------------

### 定义

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/mm/memory.c/high_memory.md

### 初始化

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/sanity_check_meminfo.md
