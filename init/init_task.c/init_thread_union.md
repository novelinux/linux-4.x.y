init_thread_union
========================================

系统启动的时候，内核为进程0首先分配了一个thread_union --> init_thread_union;
然后将内核栈指针sp指向了init_thread_union + THREAD_START_SP.

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head-common.S/__mmap_switched.md

init_thread_union
----------------------------------------

path: init/init_task.c
```
/*
 * Initial thread structure. Alignment of this is handled by a special
 * linker map entry.
 */
union thread_union init_thread_union __init_task_data =
    { INIT_THREAD_INFO(init_task) };
```

union thread_union
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/sched.h/union_thread_union.md

__init_task_data
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/init_task.h/__init_task_data.md

init_thread_union的内容就展开成了：
// 数据放进指定的数据段.data..init_task
```
union thread_union init_thread_union __attribute__((__section__(".data..init_task"))) =
    { INIT_THREAD_INFO(init_task) };
```

INIT_THREAD_INFO
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/thread_info.h/INIT_THREAD_INFO.md
