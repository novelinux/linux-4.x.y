THREAD_SIZE
========================================

path: arch/arm/include/asm/thread_info.h
```
#define THREAD_SIZE_ORDER   1
#define THREAD_SIZE        (PAGE_SIZE << THREAD_SIZE_ORDER)
#define THREAD_START_SP    (THREAD_SIZE - 8)
```