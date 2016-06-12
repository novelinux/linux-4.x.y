copy_thread
========================================

Arguments
----------------------------------------

path: arch/arm/kernel/process.c
```
asmlinkage void ret_from_fork(void) __asm__("ret_from_fork");

int
copy_thread(unsigned long clone_flags, unsigned long stack_start,
        unsigned long stk_sz, struct task_struct *p)
{
    struct thread_info *thread = task_thread_info(p);
```

task_pt_regs
----------------------------------------

获取stack中存放用户态寄存器组的偏移地址

```
    struct pt_regs *childregs = task_pt_regs(p);
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/processor.h/task_pt_regs.md

Set context
----------------------------------------

这个函数前半部分设置子进程的返回值和用户态的栈地址，其他的用户态的寄存器值和和父进程一样；
后半部分设置内核态的栈地址和pc指针,也就是设置子进程被schedule调度后,会ret_from_fork函数开始运行.

```
    // 子进程内核态的上下文保存在thread_info里
    memset(&thread->cpu_context, 0, sizeof(struct cpu_context_save));

#ifdef CONFIG_CPU_USE_DOMAINS
    /*
     * Copy the initial value of the domain access control register
     * from the current thread: thread->addr_limit will have been
     * copied from the current thread via setup_thread_stack() in
     * kernel/fork.c
     */
    thread->cpu_domain = get_domain();
#endif

    // 1.如果不是内核线程则执行如下流程:
    if (likely(!(p->flags & PF_KTHREAD))) {
        *childregs = *current_pt_regs();
        childregs->ARM_r0 = 0;   // 只修改子进程的r0和sp寄存器，其中r0保存子进程的返回值0
        if (stack_start)
            childregs->ARM_sp = stack_start; // sp是子进程的用户态栈
    // 如果是内核线程则执行如下流程.
    } else {
        memset(childregs, 0, sizeof(struct pt_regs));
        thread->cpu_context.r4 = stk_sz;
        thread->cpu_context.r5 = stack_start;
        childregs->ARM_cpsr = SVC_MODE;
    }
    // 子进程的内核态的pc地址
    thread->cpu_context.pc = (unsigned long)ret_from_fork;
    // 子进程内核态栈
    thread->cpu_context.sp = (unsigned long)childregs;

    clear_ptrace_hw_breakpoint(p);

    if (clone_flags & CLONE_SETTLS)
        thread->tp_value[0] = childregs->ARM_r3;
    thread->tp_value[1] = get_tpuser();

    thread_notify(THREAD_NOTIFY_COPY, thread);

    return 0;
}
```

struct thread_info
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/thread_info.h/thread_info.md

在内核栈中struct cpu_context_save同struct pt_regs位置如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/thread_info.h/res/threadinfo.png
