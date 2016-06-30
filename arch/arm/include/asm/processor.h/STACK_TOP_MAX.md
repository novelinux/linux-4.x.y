STACK_TOP_MAX
========================================

STACK_TOP_MAX等同于TASK_SIZE

path:arch/arm/include/asm/processor.h
```
#ifdef __KERNEL__
#define STACK_TOP ((current->personality & ADDR_LIMIT_32BIT) ? \
             TASK_SIZE : TASK_SIZE_26)
#define STACK_TOP_MAX    TASK_SIZE
f#endif
```

TASK_SIZE
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory.h/TASK_SIZE.md