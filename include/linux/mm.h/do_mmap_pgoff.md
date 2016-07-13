do_mmap_pgoff
========================================

path: include/linux/mm.h
```
static inline unsigned long
do_mmap_pgoff(struct file *file, unsigned long addr,
    unsigned long len, unsigned long prot, unsigned long flags,
    unsigned long pgoff, unsigned long *populate)
{
    return do_mmap(file, addr, len, prot, flags, 0, pgoff, populate);
}
```

do_mmap
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/do_mmap.md
