do_PrefetchAbort
========================================

OS接管后的操作首先判断发生TLBmiss的那条指令是用户指令还是系统指令，如果是系统指令则
剩余工作是对页全局目录（pgd）,页上级目录（pud），页中间目录（pmd）进行操作；
如果是用户指令，则调用do_page_fault函数，剩下的工作就是page fault的处理过程，
根据不同情况判断，包括权限检查，分配页面，发送SIGSEGV信号给进程，直接杀死进程等。
不管哪种操作，OS都没有对TLB进行重填。

Arguments
----------------------------------------

path: arch/arm/mm/fault.c
```
asmlinkage void __exception
do_PrefetchAbort(unsigned long addr, unsigned int ifsr, struct pt_regs *regs)
{
    const struct fsr_info *inf = ifsr_info + fsr_fs(ifsr);
    struct siginfo info;
```

inf->fn
----------------------------------------

```
    if (!inf->fn(addr, ifsr | FSR_LNX_PF, regs))
        return;
```

通过钩子的形式直接就调了do_page_fault:

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/fault.c/do_page_fault.md

arm_notify_die
----------------------------------------

```
    pr_alert("Unhandled prefetch abort: %s (0x%03x) at 0x%08lx\n",
        inf->name, ifsr, addr);

    info.si_signo = inf->sig;
    info.si_errno = 0;
    info.si_code  = inf->code;
    info.si_addr  = (void __user *)addr;
    arm_notify_die("", regs, &info, ifsr, 0);
}
```