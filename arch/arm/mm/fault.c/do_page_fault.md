do_page_fault
========================================

Arguments
----------------------------------------

path: arch/arm/mm/fault.c
```
static int __kprobes
do_page_fault(unsigned long addr, unsigned int fsr, struct pt_regs *regs)
{
    struct task_struct *tsk;
    struct mm_struct *mm;
    int fault, sig, code;
    unsigned int flags = FAULT_FLAG_ALLOW_RETRY | FAULT_FLAG_KILLABLE;

    if (notify_page_fault(regs, fsr))
        return 0;

    tsk = current;
    mm  = tsk->mm;

    /* Enable interrupts if they were enabled in the parent context. */
    if (interrupts_enabled(regs))
        local_irq_enable();

    /*
     * If we're in an interrupt or have no user
     * context, we must not take the fault..
     */
    if (faulthandler_disabled() || !mm)
        goto no_context;

    if (user_mode(regs))
        flags |= FAULT_FLAG_USER;
    if (fsr & FSR_WRITE)
        flags |= FAULT_FLAG_WRITE;

    /*
     * As per x86, we may deadlock here.  However, since the kernel only
     * validly references user space from well defined areas of the code,
     * we can bug out early if this is from code which shouldn't.
     */
    if (!down_read_trylock(&mm->mmap_sem)) {
        if (!user_mode(regs) && !search_exception_tables(regs->ARM_pc))
            goto no_context;
retry:
        down_read(&mm->mmap_sem);
    } else {
        /*
         * The above down_read_trylock() might have succeeded in
         * which case, we'll have missed the might_sleep() from
         * down_read()
         */
        might_sleep();
#ifdef CONFIG_DEBUG_VM
        if (!user_mode(regs) &&
            !search_exception_tables(regs->ARM_pc))
            goto no_context;
#endif
    }
```

__do_page_fault
----------------------------------------

```
    fault = __do_page_fault(mm, addr, fsr, flags, tsk);

    /* If we need to retry but a fatal signal is pending, handle the
     * signal first. We do not need to release the mmap_sem because
     * it would already be released in __lock_page_or_retry in
     * mm/filemap.c. */
    if ((fault & VM_FAULT_RETRY) && fatal_signal_pending(current))
        return 0;
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/fault.c/__do_page_fault.md

----------------------------------------

```
    /*
     * Major/minor page fault accounting is only done on the
     * initial attempt. If we go through a retry, it is extremely
     * likely that the page will be found in page cache at that point.
     */

    perf_sw_event(PERF_COUNT_SW_PAGE_FAULTS, 1, regs, addr);
    if (!(fault & VM_FAULT_ERROR) && flags & FAULT_FLAG_ALLOW_RETRY) {
        if (fault & VM_FAULT_MAJOR) {
            tsk->maj_flt++;
            perf_sw_event(PERF_COUNT_SW_PAGE_FAULTS_MAJ, 1,
                    regs, addr);
        } else {
            tsk->min_flt++;
            perf_sw_event(PERF_COUNT_SW_PAGE_FAULTS_MIN, 1,
                    regs, addr);
        }
        if (fault & VM_FAULT_RETRY) {
            /* Clear FAULT_FLAG_ALLOW_RETRY to avoid any risk
            * of starvation. */
            flags &= ~FAULT_FLAG_ALLOW_RETRY;
            flags |= FAULT_FLAG_TRIED;
            goto retry;
        }
    }

    up_read(&mm->mmap_sem);

    /*
     * Handle the "normal" case first - VM_FAULT_MAJOR / VM_FAULT_MINOR
     */
    if (likely(!(fault & (VM_FAULT_ERROR | VM_FAULT_BADMAP | VM_FAULT_BADACCESS))))
        return 0;

    /*
     * If we are in kernel mode at this point, we
     * have no context to handle this fault with.
     */
    if (!user_mode(regs))
        goto no_context;

    if (fault & VM_FAULT_OOM) {
        /*
         * We ran out of memory, call the OOM killer, and return to
         * userspace (which will retry the fault, or kill us if we
         * got oom-killed)
         */
        pagefault_out_of_memory();
        return 0;
    }

    if (fault & VM_FAULT_SIGBUS) {
        /*
         * We had some memory, but were unable to
         * successfully fix up this page fault.
         */
        sig = SIGBUS;
        code = BUS_ADRERR;
    } else {
        /*
         * Something tried to access memory that
         * isn't in our memory map..
         */
        sig = SIGSEGV;
        code = fault == VM_FAULT_BADACCESS ?
            SEGV_ACCERR : SEGV_MAPERR;
    }

    __do_user_fault(tsk, addr, fsr, sig, code, regs);
    return 0;

no_context:
    __do_kernel_fault(mm, addr, fsr, regs);
    return 0;
}
```