sys_brk
========================================

堆是进程中用于动态分配变量和数据的内存区域，堆的管理对应用程序员不是直接可见的。
因为它依赖标准库提供的各个辅助函数（其中最重要的是malloc）来分配任意长度的内存区。
malloc和内核之间的经典接口是brk系统调用，负责扩展/收缩堆。新近的malloc实现（诸如
GNU标准库提供的）使用了一种组合方法，使用brk和匿名映射。该方法提供了更好的性能，
而且在分配较大的内存区时具有某些优点。堆是一个连续的内存区域，在扩展时自下至上增长。
前文提到的mm_struct结构，包含了堆在虚拟地址空间中的起始和当前结束地址（start_brk和brk）。

Arguments
----------------------------------------

brk系统调用只需要一个参数，用于指定堆在虚拟地址空间中新的结束地址.

path: mm/mmap.c
```
SYSCALL_DEFINE1(brk, unsigned long, brk)
{
    unsigned long retval;
    unsigned long newbrk, oldbrk;
    struct mm_struct *mm = current->mm;
    unsigned long min_brk;
    bool populate;

    down_write(&mm->mmap_sem);
```

min_brk
----------------------------------------

```
#ifdef CONFIG_COMPAT_BRK
    /*
     * CONFIG_COMPAT_BRK can still be overridden by setting
     * randomize_va_space to 2, which will still cause mm->start_brk
     * to be arbitrarily shifted
     */
    if (current->brk_randomized)
        min_brk = mm->start_brk;
    else
        min_brk = mm->end_data;
#else
    min_brk = mm->start_brk;
#endif
    if (brk < min_brk)
        goto out;
```

check_data_rlimit
----------------------------------------

```
    /*
     * Check against rlimit here. If this check is done later after the test
     * of oldbrk with newbrk then it can escape the test and let the data
     * segment grow beyond its set limit the in case where the limit is
     * not page aligned -Ram Gupta
     */
    if (check_data_rlimit(rlimit(RLIMIT_DATA), brk, mm->start_brk,
                  mm->end_data, mm->start_data))
        goto out;
```

PAGE_ALIGN
----------------------------------------

```
    newbrk = PAGE_ALIGN(brk);
    oldbrk = PAGE_ALIGN(mm->brk);
    if (oldbrk == newbrk)
        goto set_brk;
```

do_munmap
----------------------------------------

在需要收缩堆时将调用do_munmap.

```
    /* Always allow shrinking brk. */
    if (brk <= mm->brk) {
        if (!do_munmap(mm, newbrk, oldbrk-newbrk))
            goto set_brk;
        goto out;
    }
```

find_vma_intersection
----------------------------------------

如果堆将要扩大，内核首先必须检查新的长度是否超出进程的最大堆长度限制。
find_vma_intersection接下来检查扩大的堆是否与进程中现存的映射重叠。
倘若如此，则什么也不做，立即返回。

```
    /* Check against existing mmap mappings. */
    if (find_vma_intersection(mm, oldbrk, newbrk+PAGE_SIZE))
        goto out;
```

do_brk
----------------------------------------

```
    /* Ok, looks good - let it rip. */
    if (do_brk(oldbrk, newbrk-oldbrk) != oldbrk)
        goto out;
```

否则将扩大堆的实际工作委托给do_brk。函数总是返回mm->brk的新值，
无论与原值相比是增大、缩小、还是不变。

set_brk
----------------------------------------

```
set_brk:
    mm->brk = brk;
    populate = newbrk > oldbrk && (mm->def_flags & VM_LOCKED) != 0;
    up_write(&mm->mmap_sem);
    if (populate)
        mm_populate(oldbrk, newbrk - oldbrk);
    return brk;

out:
    retval = mm->brk;
    up_write(&mm->mmap_sem);
    return retval;
}
```