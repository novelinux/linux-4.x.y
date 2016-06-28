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

因此可用的内核栈长度略小于8 KiB，其中一部分被thread_info实例占据。不过要注意，配置选项4KSTACKS会
将栈长度降低到4KiB，即一个页面。如果系统上有许多进程在运行，这样做是有利的，因为每个进程可以节省
一个页面。另一方面，对于经常趋向于使用过多栈空间的外部驱动程序来说，这可能导致问题。标准发布版
所提供的内核，其所有核心部分都已经设计为能够在4 KiB栈长度配置下运转流畅，但一旦需要只提供二进制
代码的驱动程序，就可能引发问题（糟糕的是，过去已经发生过这类问题），此类驱动通常习于向可用的栈
空间乱塞数据。

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/fork.c/res/kernel_stack.jpg
