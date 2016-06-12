THREAD_SIZE
========================================

path: arch/arm/include/asm/thread_info.h
```
#define THREAD_SIZE_ORDER   1
#define THREAD_SIZE        (PAGE_SIZE << THREAD_SIZE_ORDER)
#define THREAD_START_SP    (THREAD_SIZE - 8)
```

这里THREAD_SIZE_ORDER值为1，也就是说这个thread_info结构需要2个页8KB的空间。
这个8KB空间分为两部分，一部分保存thread_info值，另一部分当做线程的内核栈来用。
也就是8KB空间的起始位置+sizeof(thread_info)的位置。

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/fork.c/res/kernel_stack.jpg