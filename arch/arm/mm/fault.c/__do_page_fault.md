__do_page_fault
========================================

Arguments
----------------------------------------

path: arch/arm/mm/fault.c
```
static int __kprobes
__do_page_fault(struct mm_struct *mm, unsigned long addr, unsigned int fsr,
        unsigned int flags, struct task_struct *tsk)
{
    struct vm_area_struct *vma;
    int fault;
```

find_vma
----------------------------------------

```
    vma = find_vma(mm, addr);
    fault = VM_FAULT_BADMAP;
    if (unlikely(!vma))
        goto out;
    if (unlikely(vma->vm_start > addr))
        goto check_stack;
```

access_error
----------------------------------------

```
    /*
     * Ok, we have a good vm_area for this
     * memory access, so we can handle it.
     */
good_area:
    if (access_error(fsr, vma)) {
        fault = VM_FAULT_BADACCESS;
        goto out;
    }
```

handle_mm_fault
----------------------------------------

```
    return handle_mm_fault(mm, vma, addr & PAGE_MASK, flags);
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/memory.c/handle_mm_fault.md

check_stack
----------------------------------------

```
check_stack:
    /* Don't allow expansion below FIRST_USER_ADDRESS */
    if (vma->vm_flags & VM_GROWSDOWN &&
        addr >= FIRST_USER_ADDRESS && !expand_stack(vma, addr))
        goto good_area;
out:
    return fault;
}
```