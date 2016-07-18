vm_brk
========================================

Arguments
----------------------------------------

path: mm/mmap.c
```
unsigned long vm_brk(unsigned long addr, unsigned long len)
{
    struct mm_struct *mm = current->mm;
    unsigned long ret;
    bool populate;
```

do_brk
----------------------------------------

```
    down_write(&mm->mmap_sem);
    ret = do_brk(addr, len);
    populate = ((mm->def_flags & VM_LOCKED) != 0);
    up_write(&mm->mmap_sem);
    if (populate)
        mm_populate(addr, len);
    return ret;
}
EXPORT_SYMBOL(vm_brk);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/do_brk.md