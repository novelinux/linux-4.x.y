union thread_union
========================================

通常栈和thread_info一同保存在一个联合中thread_union中.

thread_info
----------------------------------------

path: include/linux/sched.h
```
union thread_union {
    struct thread_info thread_info;
```

thread_info保存了特定于体系结构的汇编语言代码需要访问的那部分进程数据。

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/thread_info.h/struct_thread_info.md

stack
----------------------------------------

```
    unsigned long stack[THREAD_SIZE/sizeof(long)];
};
```

在大多数体系结构上，使用一两个内存页来保存一个thread_union的实例。在ARM上，两个内存页是默认设置，

### THREAD_SIZE

#### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/thread_info.h/THREAD_SIZE.md
