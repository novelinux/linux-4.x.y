TASK_SIZE
========================================

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