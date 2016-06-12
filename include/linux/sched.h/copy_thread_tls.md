copy_thread_tls
========================================

path: include/linux/sched.h
```
#ifdef CONFIG_HAVE_COPY_THREAD_TLS
extern int copy_thread_tls(unsigned long, unsigned long, unsigned long,
            struct task_struct *, unsigned long);
#else
extern int copy_thread(unsigned long, unsigned long, unsigned long,
            struct task_struct *);

/* Architectures that haven't opted into copy_thread_tls get the tls argument
 * via pt_regs, so ignore the tls argument passed via C. */
static inline int copy_thread_tls(
        unsigned long clone_flags, unsigned long sp, unsigned long arg,
        struct task_struct *p, unsigned long tls)
{
    return copy_thread(clone_flags, sp, arg, p);
}
#endif
```

copy_thread
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/kernel/process.c/copy_thread.md
