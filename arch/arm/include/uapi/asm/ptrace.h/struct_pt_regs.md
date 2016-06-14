struct pt_regs
========================================

path: arch/arm/include/uapi/asm/ptrace.h
```
/*
 * This struct defines the way the registers are stored on the
 * stack during a system call.  Note that sizeof(struct pt_regs)
 * has to be a multiple of 8.
 */
#ifndef __KERNEL__
struct pt_regs {
    long uregs[18];
};
#endif /* __KERNEL__ */
```