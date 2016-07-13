vm_mmap_pgoff
========================================

vm_mmap_pgoff函数在进行完映射文件的安全性检查之后调用do_mmap_pgoff
函数来进行映射操作，该函数才是内存映射的主要函数:

Arguments
----------------------------------------

path: mm/util.c
```
unsigned long vm_mmap_pgoff(struct file *file, unsigned long addr,
    unsigned long len, unsigned long prot,
    unsigned long flag, unsigned long pgoff)
{
    unsigned long ret;
    struct mm_struct *mm = current->mm;
    unsigned long populate;
```

security_mmap_file
----------------------------------------

```
    ret = security_mmap_file(file, prot, flag);
```

do_mmap_pgoff
----------------------------------------

```
    if (!ret) {
        down_write(&mm->mmap_sem);
        ret = do_mmap_pgoff(file, addr, len, prot, flag, pgoff,
                    &populate);
        up_write(&mm->mmap_sem);
        if (populate)
            mm_populate(ret, populate);
    }
    return ret;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mm.h/do_mmap_pgoff.md