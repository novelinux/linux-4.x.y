# do_page_fault

```
static int __kprobes do_page_fault(unsigned long addr, unsigned int esr,
				   struct pt_regs *regs)
{
	const struct fault_info *inf;
	struct mm_struct *mm = current->mm;
	vm_fault_t fault, major = 0;
	unsigned long vm_flags = VM_READ | VM_WRITE;
	unsigned int mm_flags = FAULT_FLAG_ALLOW_RETRY | FAULT_FLAG_KILLABLE;

	if (kprobe_page_fault(regs, esr))
		return 0;

	/*
	 * If we're in an interrupt or have no user context, we must not take
	 * the fault.
	 */
	if (faulthandler_disabled() || !mm)
		goto no_context;

	if (user_mode(regs))
		mm_flags |= FAULT_FLAG_USER;

	if (is_el0_instruction_abort(esr)) {
		vm_flags = VM_EXEC;
		mm_flags |= FAULT_FLAG_INSTRUCTION;
	} else if (is_write_abort(esr)) {
		vm_flags = VM_WRITE;
		mm_flags |= FAULT_FLAG_WRITE;
	}

	if (is_ttbr0_addr(addr) && is_el1_permission_fault(addr, esr, regs)) {
		/* regs->orig_addr_limit may be 0 if we entered from EL0 */
		if (regs->orig_addr_limit == KERNEL_DS)
			die_kernel_fault("access to user memory with fs=KERNEL_DS",
					 addr, esr, regs);

		if (is_el1_instruction_abort(esr))
			die_kernel_fault("execution of user memory",
					 addr, esr, regs);

		if (!search_exception_tables(regs->pc))
			die_kernel_fault("access to user memory outside uaccess routines",
					 addr, esr, regs);
	}

	perf_sw_event(PERF_COUNT_SW_PAGE_FAULTS, 1, regs, addr);

	/*
	 * As per x86, we may deadlock here. However, since the kernel only
	 * validly references user space from well defined areas of the code,
	 * we can bug out early if this is from code which shouldn't.
	 */
	if (!down_read_trylock(&mm->mmap_sem)) {
		if (!user_mode(regs) && !search_exception_tables(regs->pc))
			goto no_context;
retry:
		down_read(&mm->mmap_sem);
	} else {
		/*
		 * The above down_read_trylock() might have succeeded in which
		 * case, we'll have missed the might_sleep() from down_read().
		 */
		might_sleep();
#ifdef CONFIG_DEBUG_VM
		if (!user_mode(regs) && !search_exception_tables(regs->pc)) {
			up_read(&mm->mmap_sem);
			goto no_context;
		}
#endif
	}
```	

### __do_page_fault

```
	fault = __do_page_fault(mm, addr, mm_flags, vm_flags);
	major |= fault & VM_FAULT_MAJOR;

	if (fault & VM_FAULT_RETRY) {
		/*
		 * If we need to retry but a fatal signal is pending,
		 * handle the signal first. We do not need to release
		 * the mmap_sem because it would already be released
		 * in __lock_page_or_retry in mm/filemap.c.
		 */
		if (fatal_signal_pending(current)) {
			if (!user_mode(regs))
				goto no_context;
			return 0;
		}

		/*
		 * Clear FAULT_FLAG_ALLOW_RETRY to avoid any risk of
		 * starvation.
		 */
		if (mm_flags & FAULT_FLAG_ALLOW_RETRY) {
			mm_flags &= ~FAULT_FLAG_ALLOW_RETRY;
			mm_flags |= FAULT_FLAG_TRIED;
			goto retry;
		}
	}
	up_read(&mm->mmap_sem);

	/*
	 * Handle the "normal" (no error) case first.
	 */
	if (likely(!(fault & (VM_FAULT_ERROR | VM_FAULT_BADMAP |
			      VM_FAULT_BADACCESS)))) {
		/*
		 * Major/minor page fault accounting is only done
		 * once. If we go through a retry, it is extremely
		 * likely that the page will be found in page cache at
		 * that point.
		 */
		if (major) {
			current->maj_flt++;
			perf_sw_event(PERF_COUNT_SW_PAGE_FAULTS_MAJ, 1, regs,
				      addr);
		} else {
			current->min_flt++;
			perf_sw_event(PERF_COUNT_SW_PAGE_FAULTS_MIN, 1, regs,
				      addr);
		}

		return 0;
	}

	/*
	 * If we are in kernel mode at this point, we have no context to
	 * handle this fault with.
	 */
	if (!user_mode(regs))
		goto no_context;

	if (fault & VM_FAULT_OOM) {
		/*
		 * We ran out of memory, call the OOM killer, and return to
		 * userspace (which will retry the fault, or kill us if we got
		 * oom-killed).
		 */
		pagefault_out_of_memory();
		return 0;
	}

	inf = esr_to_fault_info(esr);
	set_thread_esr(addr, esr);
	if (fault & VM_FAULT_SIGBUS) {
		/*
		 * We had some memory, but were unable to successfully fix up
		 * this page fault.
		 */
		arm64_force_sig_fault(SIGBUS, BUS_ADRERR, (void __user *)addr,
				      inf->name);
	} else if (fault & (VM_FAULT_HWPOISON_LARGE | VM_FAULT_HWPOISON)) {
		unsigned int lsb;

		lsb = PAGE_SHIFT;
		if (fault & VM_FAULT_HWPOISON_LARGE)
			lsb = hstate_index_to_shift(VM_FAULT_GET_HINDEX(fault));

		arm64_force_sig_mceerr(BUS_MCEERR_AR, (void __user *)addr, lsb,
				       inf->name);
	} else {
		/*
		 * Something tried to access memory that isn't in our memory
		 * map.
		 */
		arm64_force_sig_fault(SIGSEGV,
				      fault == VM_FAULT_BADACCESS ? SEGV_ACCERR : SEGV_MAPERR,
				      (void __user *)addr,
				      inf->name);
	}

	return 0;
```

### __do_kernel_fault

```
no_context:
	__do_kernel_fault(addr, esr, regs);
	return 0;
}
```