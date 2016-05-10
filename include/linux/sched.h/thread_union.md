union thread_union
========================================

通常栈和thread_info一同保存在一个联合中thread_union中.

path: include/linux/sched.h
```
union thread_union {
    struct thread_info thread_info;
    unsigned long stack[THREAD_SIZE/sizeof(long)];
};
```

在大多数体系结构上，使用一两个内存页来保存一个thread_union的实例。在ARM上，两个内存页是默认设置，

path: arch/arm/include/asm/thread_info.h
```
#define THREAD_SIZE             8192
#define THREAD_START_SP         (THREAD_SIZE - 8)
```

因此可用的内核栈长度略小于8 KiB，其中一部分被thread_info实例占据。不过要注意，配置选项4KSTACKS会
将栈长度降低到4KiB，即一个页面。如果系统上有许多进程在运行，这样做是有利的，因为每个进程可以节省
一个页面。另一方面，对于经常趋向于使用过多栈空间的外部驱动程序来说，这可能导致问题。标准发布版
所提供的内核，其所有核心部分都已经设计为能够在4 KiB栈长度配置下运转流畅，但一旦需要只提供二进制
代码的驱动程序，就可能引发问题（糟糕的是，过去已经发生过这类问题），此类驱动通常习于向可用的栈
空间乱塞数据。

struct thread_info
----------------------------------------

thread_info保存了特定于体系结构的汇编语言代码需要访问的那部分进程数据。

### arm

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/thread_info.h/thread_info.md

current vs current_thread_info
----------------------------------------

所有体系结构都将两个名为current和current_thread_info的符号定义为宏或函数。其语义如下所示:

* current_thread_info可获得指向当前执行进程的thread_info实例的指针。其地址可以根据内核栈
指针确定，因为thread_info实例总是位于栈顶。因为每个进程分别使用各自的内核栈，进程到栈的
映射是唯一的。

* current给出了当前进程task_struct实例的地址。该函数在源代码中出现非常频繁。该地址可以使用
current_thread_info()确定：current = current_thread_info()->task。