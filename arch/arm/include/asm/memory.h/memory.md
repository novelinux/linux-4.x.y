memory layout
========================================

几个与进程内存布局相关常用宏的定义如下所示：

TASK_SIZE
----------------------------------------

TASK_SIZE大约位于3GB - 16MB位置处.

path: arch/arm/include/asm/memory.h
```
#ifdef CONFIG_MMU

/*
 * TASK_SIZE - the maximum size of a user space task.
 * TASK_UNMAPPED_BASE - the lower boundary of the mmap VM area
 */
#define TASK_SIZE             (UL(CONFIG_PAGE_OFFSET) - UL(SZ_16M))
#define TASK_UNMAPPED_BASE    ALIGN(TASK_SIZE / 3, SZ_16M)
...
```

path: include/linux/sizes.h
```
#define SZ_16M                              0x01000000
```

一般CONFIG_PAGE_OFFSET的值配置如下所示:

```
CONFIG_PAGE_OFFSET=0xC0000000  // 3GB
```

TASK_UNMAPPED_BASE
----------------------------------------

TASK_UNMAPPED_BASE大约位于TASK_SIZE / 3位置处.

path: arch/arm/include/asm/memory.h
```
#ifdef CONFIG_MMU
...
#define TASK_UNMAPPED_BASE    ALIGN(TASK_SIZE / 3, SZ_16M)
...
```

STACK_TOP
----------------------------------------

STACK_TOP在32位机器上通常都等同于TASK_SIZE

path:arch/arm/include/asm/processor.h
```
#ifdef __KERNEL__
#define STACK_TOP    ((current->personality & ADDR_LIMIT_32BIT) ? \
                       TASK_SIZE : TASK_SIZE_26)
...
#endif
```

STACK_TOP_MAX
----------------------------------------

STACK_TOP_MAX等同于TASK_SIZE

path:arch/arm/include/asm/processor.h
```
#ifdef __KERNEL__
...
#define STACK_TOP_MAX    TASK_SIZE
#endif
```