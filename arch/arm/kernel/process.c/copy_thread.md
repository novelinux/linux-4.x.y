copy_thread
========================================

path: arch/arm/kernel/process.c
```
asmlinkage void ret_from_fork(void) __asm__("ret_from_fork");

int
copy_thread(unsigned long clone_flags, unsigned long stack_start,
        unsigned long stk_sz, struct task_struct *p, struct pt_regs *regs)
{
    struct thread_info *thread = task_thread_info(p);
    // 获取stack中存放用户态寄存器组的偏移地址
    struct pt_regs *childregs = task_pt_regs(p);

    // 将父进程的用户态寄存器组拷贝给子进程
    *childregs = *regs;
    // 只修改子进程的r0和sp寄存器，其中r0保存子进程的返回值0
    childregs->ARM_r0 = 0;
    // sp是子进程的用户态栈
    childregs->ARM_sp = stack_start;

    //子进程内核态的上下文保存在thread_info里
    memset(&thread->cpu_context, 0, sizeof(struct cpu_context_save));
    // 子进程内核态栈
    thread->cpu_context.sp = (unsigned long)childregs;
    // 子进程的内核态的pc地址
    thread->cpu_context.pc = (unsigned long)ret_from_fork;

    clear_ptrace_hw_breakpoint(p);

    if (clone_flags & CLONE_SETTLS)
        thread->tp_value = regs->ARM_r3;

    thread_notify(THREAD_NOTIFY_COPY, thread);

    return 0;
}
```

这个函数前半部分设置子进程的返回值和用户态的栈地址，其他的用户态的寄存器值和和父进程一样；
后半部分设置内核态的栈地址和pc指针,也就是设置子进程被schedule调度后,会ret_from_fork函数开始运行.

### struct thread_info

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/thread_info.h/thread_info.md

task_pt_regs
----------------------------------------

path: arch/arm/include/asm/processor.h
```
#define task_pt_regs(p) \
	((struct pt_regs *)(THREAD_START_SP + task_stack_page(p)) - 1)
```

path: include/linux/sched.h
```
#define task_stack_page(task)	((task)->stack)
```

在内核栈中struct cpu_context_save同struct pt_regs位置如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/thread_info.h/res/threadinfo.png
