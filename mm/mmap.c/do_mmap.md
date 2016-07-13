do_mmap
========================================

do_mmap是一个体系结构无关的函数,此函数曾经是内核中最长的函数之一,
它现在已经分成两个部分,但仍然相当长,第一部分需要彻底检查用户应用程序
传递的参数; 第二部分需要考虑大量特殊情况和微妙之处.

Arguments
----------------------------------------

path: mm/mmap.c
```
/*
 * The caller must hold down_write(&current->mm->mmap_sem).
 */
unsigned long do_mmap(struct file *file, unsigned long addr,
            unsigned long len, unsigned long prot,
            unsigned long flags, vm_flags_t vm_flags,
            unsigned long pgoff, unsigned long *populate)
{
    struct mm_struct *mm = current->mm;

    *populate = 0;

    if (!len)
        return -EINVAL;
```

Checking
----------------------------------------

```
    /*
     * Does the application expect PROT_READ to imply PROT_EXEC?
     *
     * (the exception is when the underlying filesystem is noexec
     *  mounted, in which case we dont add PROT_EXEC.)
     */
    if ((prot & PROT_READ) && (current->personality & READ_IMPLIES_EXEC))
        if (!(file && path_noexec(&file->f_path)))
            prot |= PROT_EXEC;

    if (!(flags & MAP_FIXED))
        addr = round_hint_to_min(addr);

    /* Careful about overflows.. */
    len = PAGE_ALIGN(len);
    if (!len)
        return -ENOMEM;

    /* offset overflow? */
    if ((pgoff + (len >> PAGE_SHIFT)) < pgoff)
        return -EOVERFLOW;

    /* Too many mappings? */
     /* 每个进程有最多可以用来映射的内存个数sysctl_max_map_count.
      * 如果已经存在了足够多的内存映射，则返回失败。
      */
    if (mm->map_count > sysctl_max_map_count)
        return -ENOMEM;
```

get_unmapped_area
----------------------------------------

get_unmapped_area函数用于在进程虚拟地址空间中找到一个合适的区域用于映射.

```
    /* Obtain the address to map to. we verify (or select) it and ensure
     * that it represents a valid section of the address space.
     */
    addr = get_unmapped_area(file, addr, len, pgoff, flags);
    if (offset_in_page(addr))
        return addr;
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/get_unmapped_area.md

vm_flags
----------------------------------------

calc_vm_prot_bits和calc_vm_flag_bits这两个调用将系统调用中指定的标志
和访问权限常数合并到一个共同的标志集中,在后续操作中比较易于处理
(MAP_和PROT_标志转换为前缀VM_的标志).内核从当前运行进程的mm_struct实例
中获得def_flags之后，又将其包含到标志集中. def_flags的值为0或者VM_LOCK.
前者不会改变结果标志集,而VM_LOCK意味着随后映射的页无法换出.为设置
def_flags的值，进程必须发出mlockall系统调用，使用上述机制防止所有未来
映射被换出，即使在创建时没有显示指定VM_LOCK标志也是如此.

```
    /* Do simple checking here so the lower-level routines won't have
     * to. we assume access permissions have been handled by the open
     * of the memory object, so we don't do any here.
     */
    vm_flags |= calc_vm_prot_bits(prot) | calc_vm_flag_bits(flags) |
            mm->def_flags | VM_MAYREAD | VM_MAYWRITE | VM_MAYEXEC;

    if (flags & MAP_LOCKED)
        if (!can_do_mlock())
            return -EPERM;

    if (mlock_future_check(mm, vm_flags, len))
        return -EAGAIN;
```

flags
----------------------------------------

* MAP_FIXED: 指定了除了给定地址以外，不能将其它地址用于映射. 如果没有设置
该标志，内核可以在受阻的情况下随时改变目标地址.
* MAP_SHARED: 如果一个对象(通常是文件)在几个进程之间共享时，必须使用MAP_SHARED.
* MAP_PRIVATE: 创建一个与数据源分离的私有映射，对映射区域的写入操作不影响文件中的数据.
* MAP_ANONYMOUS: 创建与任何数据源都不相关的匿名映射，fd和off参数被忽略. 此类映射可用于为应用程序分配类似malloc所用的内存.

```
    if (file) {
        struct inode *inode = file_inode(file);

        switch (flags & MAP_TYPE) {
        case MAP_SHARED:
            if ((prot&PROT_WRITE) && !(file->f_mode&FMODE_WRITE))
                return -EACCES;

            /*
             * Make sure we don't allow writing to an append-only
             * file..
             */
            if (IS_APPEND(inode) && (file->f_mode & FMODE_WRITE))
                return -EACCES;

            /*
             * Make sure there are no mandatory locks on the file.
             */
            if (locks_verify_locked(file))
                return -EAGAIN;

            vm_flags |= VM_SHARED | VM_MAYSHARE;
            if (!(file->f_mode & FMODE_WRITE))
                vm_flags &= ~(VM_MAYWRITE | VM_SHARED);

            /* fall through */
        case MAP_PRIVATE:
            if (!(file->f_mode & FMODE_READ))
                return -EACCES;
            if (path_noexec(&file->f_path)) {
                if (vm_flags & VM_EXEC)
                    return -EPERM;
                vm_flags &= ~VM_MAYEXEC;
            }

            if (!file->f_op->mmap)
                return -ENODEV;
            if (vm_flags & (VM_GROWSDOWN|VM_GROWSUP))
                return -EINVAL;
            break;

        default:
            return -EINVAL;
        }
    } else {
        switch (flags & MAP_TYPE) {
        case MAP_SHARED:
            if (vm_flags & (VM_GROWSDOWN|VM_GROWSUP))
                return -EINVAL;
            /*
             * Ignore pgoff.
             */
            pgoff = 0;
            vm_flags |= VM_SHARED | VM_MAYSHARE;
            break;
        case MAP_PRIVATE:
            /*
             * Set pgoff according to addr for anon_vma.
             */
            pgoff = addr >> PAGE_SHIFT;
            break;
        default:
            return -EINVAL;
        }
    }

    /*
     * Set 'VM_NORESERVE' if we should not account for the
     * memory use of this mapping.
     */
    if (flags & MAP_NORESERVE) {
        /* We honor MAP_NORESERVE if allowed to overcommit */
        if (sysctl_overcommit_memory != OVERCOMMIT_NEVER)
            vm_flags |= VM_NORESERVE;

        /* hugetlb applies strict overcommit unless MAP_NORESERVE */
        if (file && is_file_hugepages(file))
            vm_flags |= VM_NORESERVE;
    }
```

mmap_region
----------------------------------------

```
    addr = mmap_region(file, addr, len, vm_flags, pgoff);
    if (!IS_ERR_VALUE(addr) &&
        ((vm_flags & VM_LOCKED) ||
         (flags & (MAP_POPULATE | MAP_NONBLOCK)) == MAP_POPULATE))
        *populate = len;
    return addr;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/mmap_region.md