vm_mmap.md
========================================

path: mm/util.c
```
unsigned long vm_mmap(struct file *file, unsigned long addr,
    unsigned long len, unsigned long prot,
    unsigned long flag, unsigned long offset)
{
    if (unlikely(offset + PAGE_ALIGN(len) < offset))
        return -EINVAL;
    if (unlikely(offset_in_page(offset)))
        return -EINVAL;

    return vm_mmap_pgoff(file, addr, len, prot, flag, offset >> PAGE_SHIFT);
}
EXPORT_SYMBOL(vm_mmap);
```

vm_mmap_pgoff
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/util.c/vm_mmap_pgoff.md
