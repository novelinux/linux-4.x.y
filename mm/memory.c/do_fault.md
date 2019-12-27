do_fault
========================================

文件映射缺页中断又分为三种：

* flags中不包含FAULT_FLAG_WRITE，说明是只读异常，调用do_read_fault()
* VMA的vm_flags没有定义VM_SHARED，说明这是一个私有文件映射，发生了写时复制COW，调用do_cow_fault()
* 其余情况则说明是共享文件映射缺页异常，调用do_shared_fault()

path: mm/memory.c
```
/*
 * We enter with non-exclusive mmap_sem (to exclude vma changes,
 * but allow concurrent faults).
 * The mmap_sem may have been released depending on flags and our
 * return value.  See filemap_fault() and __lock_page_or_retry().
 */
static int do_fault(struct mm_struct *mm, struct vm_area_struct *vma,
        unsigned long address, pte_t *page_table, pmd_t *pmd,
        unsigned int flags, pte_t orig_pte)
{
    pgoff_t pgoff = (((address & PAGE_MASK)
            - vma->vm_start) >> PAGE_SHIFT) + vma->vm_pgoff;

    pte_unmap(page_table);
    /* The VMA was not fully populated on mmap() or missing VM_DONTEXPAND */
    if (!vma->vm_ops->fault)
        return VM_FAULT_SIGBUS;
    if (!(flags & FAULT_FLAG_WRITE))
        return do_read_fault(mm, vma, address, pmd, pgoff, flags,
                orig_pte);
    if (!(vma->vm_flags & VM_SHARED))
        return do_cow_fault(mm, vma, address, pmd, pgoff, flags,
                orig_pte);
    return do_shared_fault(mm, vma, address, pmd, pgoff, flags, orig_pte);
}
```