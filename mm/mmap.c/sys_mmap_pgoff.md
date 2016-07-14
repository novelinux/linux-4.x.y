sys_mmap_pgoff
========================================

Arguments
----------------------------------------

path: mm/mmap.c
```
SYSCALL_DEFINE6(mmap_pgoff, unsigned long, addr, unsigned long, len,
        unsigned long, prot, unsigned long, flags,
        unsigned long, fd, unsigned long, pgoff)
{
    struct file *file = NULL;
    unsigned long retval = -EBADF;
```

MAP_ANONYMOUS
----------------------------------------

```
    if (!(flags & MAP_ANONYMOUS)) {
        audit_mmap_fd(fd, flags);
        file = fget(fd);
        if (!file)
            goto out;
        if (is_file_hugepages(file))
            len = ALIGN(len, huge_page_size(hstate_file(file)));
        retval = -EINVAL;
        if (unlikely(flags & MAP_HUGETLB && !is_file_hugepages(file)))
            goto out_fput;
```

MAP_HUGETLB
----------------------------------------

```
    } else if (flags & MAP_HUGETLB) {
        struct user_struct *user = NULL;
        struct hstate *hs;

        hs = hstate_sizelog((flags >> MAP_HUGE_SHIFT) & SHM_HUGE_MASK);
        if (!hs)
            return -EINVAL;

        len = ALIGN(len, huge_page_size(hs));
        /*
         * VM_NORESERVE is used because the reservations will be
         * taken when vm_ops->mmap() is called
         * A dummy user value is used because we are not locking
         * memory so no accounting is necessary
         */
        file = hugetlb_file_setup(HUGETLB_ANON_FILE, len,
                VM_NORESERVE,
                &user, HUGETLB_ANONHUGE_INODE,
                (flags >> MAP_HUGE_SHIFT) & MAP_HUGE_MASK);
        if (IS_ERR(file))
            return PTR_ERR(file);
    }
```

vm_mmap_pgoff
----------------------------------------

```
    flags &= ~(MAP_EXECUTABLE | MAP_DENYWRITE);

    retval = vm_mmap_pgoff(file, addr, len, prot, flags, pgoff);
out_fput:
    if (file)
        fput(file);
out:
    return retval;
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/util.c/vm_mmap_pgoff.md
