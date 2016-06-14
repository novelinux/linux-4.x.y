scno, tbl, why, tsk
========================================

path: arch/arm/kernel/entry-header.S
```
/*
 * These are the registers used in the syscall handler, and allow us to
 * have in theory up to 7 arguments to a function - r0 to r6.
 *
 * r7 is reserved for the system call number for thumb mode.
 *
 * Note that tbl == why is intentional.
 *
 * We must set at least "tsk" and "why" when calling ret_with_reschedule.
 */
scno   .req    r7        @ syscall number
tbl    .req    r8        @ syscall table pointer
why    .req    r8        @ Linux syscall (!= 0)
tsk    .req    r9        @ current thread_info
```
