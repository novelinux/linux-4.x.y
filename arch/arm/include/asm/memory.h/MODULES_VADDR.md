MODULES_VADDR
========================================

path: arch/arm/include/asm/memory.h
```
#ifdef CONFIG_MMU
...
/*
 * The module space lives between the addresses given by TASK_SIZE
 * and PAGE_OFFSET - it must be within 32MB of the kernel text.
 */
#ifndef CONFIG_THUMB2_KERNEL
#define MODULES_VADDR        (PAGE_OFFSET - SZ_16M)
#else
/* smaller range for Thumb-2 symbols relocation (2^24)*/
#define MODULES_VADDR        (PAGE_OFFSET - SZ_8M)
#endif

#if TASK_SIZE > MODULES_VADDR
#error Top of user space clashes with start of module space
#endif

/*
 * The highmem pkmap virtual space shares the end of the module area.
 */
#ifdef CONFIG_HIGHMEM
#define MODULES_END        (PAGE_OFFSET - PMD_SIZE)
#else
#define MODULES_END        (PAGE_OFFSET)
#endif

#else
...
#endif
```

MODULES_VADDR为PAGE_OFFSET也即0xc0000000向下偏移的16M地址0xbf000000，它定义了内核模块加载的地址。
通过lsmod或者proc系统可以查看当前系统中的模块地址分配情况,所有的模块地址应该位于
MODULES_VADDR和MODULES_END之间。

PAGE_OFFSET
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/arch/arm/include/asm/memory_h/PAGE_OFFSET.md