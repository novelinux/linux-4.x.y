handle_mm_fault
========================================

handle_mm_fault是一个体系结构无关的例程，用于选择适当的异常
恢复方法（按需调页、换入，等等），并应用选择的方法。

如果页成功建立，则例程返回VM_FAULT_MINOR（数据已经在内存中）或
VM_FAULT_MAJOR（数据需要从块设备读取）。内核接下来更新进程的统计量。
但在创建页时，也可能发生异常。如果用于加载页的物理内存不足，内核会强制
终止该进程，在最低限度上维持系统的运行。如果对数据的访问已经允许，但由于
其他的原因失败（例如，访问的映射已经在访问的同时被另一个进程收缩，不再存
在于给定的地址），则将SIGBUS信号发送给进程。

Arguments
----------------------------------------

path: mm/memory.c
```
/*
 * By the time we get here, we already hold the mm semaphore
 *
 * The mmap_sem may have been released depending on flags and our
 * return value.  See filemap_fault() and __lock_page_or_retry().
 */
int handle_mm_fault(struct mm_struct *mm, struct vm_area_struct *vma,
            unsigned long address, unsigned int flags)
{
    int ret;

    __set_current_state(TASK_RUNNING);

    count_vm_event(PGFAULT);
    mem_cgroup_count_vm_event(mm, PGFAULT);

    /* do counter updates before entering really critical section. */
    check_sync_rss_stat(current);

    /*
     * Enable the memcg OOM handling for faults triggered in user
     * space.  Kernel faults are handled more gracefully.
     */
    if (flags & FAULT_FLAG_USER)
        mem_cgroup_oom_enable();
```

__handle_mm_fault
----------------------------------------

```
    ret = __handle_mm_fault(mm, vma, address, flags);

    if (flags & FAULT_FLAG_USER) {
        mem_cgroup_oom_disable();
                /*
                 * The task may have entered a memcg OOM situation but
                 * if the allocation error was handled gracefully (no
                 * VM_FAULT_OOM), there is no need to kill anything.
                 * Just clean up the OOM state peacefully.
                 */
                if (task_in_memcg_oom(current) && !(ret & VM_FAULT_OOM))
                        mem_cgroup_oom_synchronize(false);
    }

    return ret;
}
EXPORT_SYMBOL_GPL(handle_mm_fault);
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/memory.c/__handle_mm_fault.md
