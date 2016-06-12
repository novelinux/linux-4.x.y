task_pt_regs
========================================

path: arch/arm/include/asm/processor.h
```
#define task_pt_regs(p) \
    ((struct pt_regs *)(THREAD_START_SP + task_stack_page(p)) - 1)
```

THREAD_START_SP
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/include/asm/thread_info.h/THREAD_SIZE.md

task_stack_page
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/sched.h/task_stack_page.md
