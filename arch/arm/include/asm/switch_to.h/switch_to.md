switch_to
========================================

path: arch/arm/include/asm/switch_to.h
```
/*
 * switch_to(prev, next) should switch from task `prev' to `next'
 * `prev' will never be the same as `next'.  schedule() itself
 * contains the memory barrier to tell GCC not to cache `current'.
 */
extern struct task_struct *__switch_to(struct task_struct *, struct thread_info *, struct thread_info *);

#define switch_to(prev,next,last)                    \
do {                                                 \
    last = __switch_to(prev,task_thread_info(prev), task_thread_info(next));  \
} while (0)
```

__switch_to
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/kernel/entry-armv.S/__switch_to.md
