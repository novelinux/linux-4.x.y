TASK_SIZE
========================================

TASK_SIZE大约位于3GB - 16MB位置处.

path: arch/arm/include/asm/memory.h
```
#ifdef CONFIG_MMU

/*
 * TASK_SIZE - the maximum size of a user space task.
 * TASK_UNMAPPED_BASE - the lower boundary of the mmap VM area
 */
#define TASK_SIZE		(UL(CONFIG_PAGE_OFFSET) - UL(SZ_16M))
...
```

CONFIG_PAGE_OFFSET
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory.h/PAGE_OFFSET.md
