vm_mmap.md
========================================

* file: 表示要映射的文件;
* addr: 虚拟空间中的一个地址，表示从这个地址开始查找一个空闲的虚拟区;
* len: 要映射的文件部分的长度;
* prot: 这个参数指定对这个虚拟区所包含页的存取权限。
* flag: 这个参数指定虚拟区的其它标志;
* offset: 文件内的偏移量, 因为我们并不是一下子全部映射一个文件,
          可能只是映射文件的一部分, off就表示那部分的起始位置;

path: mm/util.c
```
unsigned long vm_mmap(struct file *file, unsigned long addr,
     unsigned long len, unsigned long prot,
     unsigned long flag, unsigned long offset)
{
    if (unlikely(offset + PAGE_ALIGN(len) < offset))
         return -EINVAL;
    if (unlikely(offset & ~PAGE_MASK))
         return -EINVAL;

    return vm_mmap_pgoff(file, addr, len, prot, flag, offset >> PAGE_SHIFT);
}
EXPORT_SYMBOL(vm_mmap);
```

vm_mmap()函数对参数offset的合法性检查后,接下来调用vm_mmap_pgoff
函数执行映射操作.

vm_mmap_pgoff
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

     ret = security_mmap_file(file, prot, flag);
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

vm_mmap_pgoff函数在进行完映射文件的安全性检查之后调用do_mmap_pgoff
函数来进行映射操作，该函数才是内存映射的主要函数:

do_mmap_pgoff
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/mmap_c/do_mmap_pgoff.md
