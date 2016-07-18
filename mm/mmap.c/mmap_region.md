mmap_region
========================================

Arguments
----------------------------------------

path: mm/mmap.c
```
unsigned long mmap_region(struct file *file, unsigned long addr,
        unsigned long len, vm_flags_t vm_flags, unsigned long pgoff)
{
    struct mm_struct *mm = current->mm;
    struct vm_area_struct *vma, *prev;
    int error;
    struct rb_node **rb_link, *rb_parent;
    unsigned long charged = 0;
```

may_expand_vm
----------------------------------------

```
    /* Check against address space limit. */
    if (!may_expand_vm(mm, len >> PAGE_SHIFT)) {
        unsigned long nr_pages;

        /*
         * MAP_FIXED may remove pages of mappings that intersects with
         * requested mapping. Account for the pages it would unmap.
         */
        if (!(vm_flags & MAP_FIXED))
            return -ENOMEM;

        nr_pages = count_vma_pages_range(mm, addr, addr + len);

        if (!may_expand_vm(mm, (len >> PAGE_SHIFT) - nr_pages))
            return -ENOMEM;
    }
```

may_expand_vm函数检查是否要对此虚拟区间进行扩充.

find_vma_links
----------------------------------------

```
    /* Clear old maps */
    error = -ENOMEM;
    while (find_vma_links(mm, addr, addr + len, &prev, &rb_link,
                  &rb_parent)) {
        if (do_munmap(mm, addr, len))
            return -ENOMEM;
    }
```

调用find_vma_links来查找前一个和后一个区域的vma_area_struct实例，
以及红黑树中节点对应的数据. 如果在指定的映射位置已经存在一个映射，

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/find_vma_links.md

accountable_mapping
----------------------------------------

```
    /*
     * Private writable mapping: check memory availability
     */
    if (accountable_mapping(file, vm_flags)) {
        charged = len >> PAGE_SHIFT;
        if (security_vm_enough_memory_mm(mm, charged))
            return -ENOMEM;
        vm_flags |= VM_ACCOUNT;
    }
```

accountable_mapping统计，即内核维护了进程用于映射的页数目统计.
由于可以限制进程的资源用量,内核必须始终确保资源使用不超过允许值.
对于每个进程可以创建的映射，还有一个最大数目的限制.

security_vm_enough_memory_mm进行广泛的安全性和合理性检查，
以防止应用程序设置无效的参数或可能影响系统稳定性的参数.

vma_merge
----------------------------------------

```
    /*
     * Can we just expand an old mapping?
     */
    vma = vma_merge(mm, prev, addr, addr + len, vm_flags,
            NULL, file, pgoff, NULL, NULL_VM_UFFD_CTX);
    if (vma)
        goto out;
```

在新区域被创建并加到进程的地址空间时，内核会检查它是否可以与一个或多个
现存区域合并. 如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/vma_merge.md

alloc vma
----------------------------------------

```
    /*
     * Determine the object being mapped and call the appropriate
     * specific mapper. the address has already been validated, but
     * not unmapped, but the maps are removed from the list.
     */
    vma = kmem_cache_zalloc(vm_area_cachep, GFP_KERNEL);
    if (!vma) {
        error = -ENOMEM;
        goto unacct_error;
    }

    vma->vm_mm = mm;
    vma->vm_start = addr;
    vma->vm_end = addr + len;
    vma->vm_flags = vm_flags;
    vma->vm_page_prot = vm_get_page_prot(vm_flags);
    vma->vm_pgoff = pgoff;
    INIT_LIST_HEAD(&vma->anon_vma_chain);
```

file->f_op->mmap
----------------------------------------

```
    if (file) {
        if (vm_flags & VM_DENYWRITE) {
            error = deny_write_access(file);
            if (error)
                goto free_vma;
        }
        if (vm_flags & VM_SHARED) {
            error = mapping_map_writable(file->f_mapping);
            if (error)
                goto allow_write_and_free_vma;
        }

        /* ->mmap() can change vma->vm_file, but must guarantee that
         * vma_link() below can deny write-access if VM_DENYWRITE is set
         * and map writably if VM_SHARED is set. This usually means the
         * new file must not have been exposed to user-space, yet.
         */
        vma->vm_file = get_file(file);
        error = file->f_op->mmap(file, vma);
        if (error)
            goto unmap_and_free_vma;

        /* Can addr have changed??
         *
         * Answer: Yes, several device drivers can do it in their
         *         f_op->mmap method. -DaveM
         * Bug: If addr is changed, prev, rb_link, rb_parent should
         *      be updated for vma_link()
         */
        WARN_ON_ONCE(addr != vma->vm_start);

        addr = vma->vm_start;
        vm_flags = vma->vm_flags;
    } else if (vm_flags & VM_SHARED) {
        error = shmem_zero_setup(vma);
        if (error)
            goto free_vma;
    }
```

### EXT4

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/file.c/ext4_file_operations.md

vma_link
----------------------------------------

```
    vma_link(mm, vma, prev, rb_link, rb_parent);
    /* Once vma denies write, undo our temporary denial count */
    if (file) {
        if (vm_flags & VM_SHARED)
            mapping_unmap_writable(file->f_mapping);
        if (vm_flags & VM_DENYWRITE)
            allow_write_access(file);
    }
    file = vma->vm_file;
```

vma_link函数将新区域合并到该进程现存的数据结构mm_struct中去.
如果VM_LOCKED被设置，或者通过系统调用的标志参数显示传递进来，或者通过mlockall机制
隐式设置，内核都会一次扫描映射中的各页，对每一页触发缺页异常以便读入其数据.当然，
这意味着失去了延迟读取带来的性能提高，但内核可以确保在映射建立后所涉及的页总在物理
内存中. 毕竟VM_LOCKED标志用来防止从内存换出页，因此这些页必须先读进来.

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/vma_link.md

out
----------------------------------------

```
out:
    perf_event_mmap(vma);

    vm_stat_account(mm, vm_flags, file, len >> PAGE_SHIFT);
    if (vm_flags & VM_LOCKED) {
        if (!((vm_flags & VM_SPECIAL) || is_vm_hugetlb_page(vma) ||
                    vma == get_gate_vma(current->mm)))
            mm->locked_vm += (len >> PAGE_SHIFT);
        else
            vma->vm_flags &= ~VM_LOCKED;
    }

    if (file)
        uprobe_mmap(vma);

    /*
     * New (or expanded) vma always get soft dirty status.
     * Otherwise user-space soft-dirty page tracker won't
     * be able to distinguish situation when vma area unmapped,
     * then new mapped in-place (which must be aimed as
     * a completely new data area).
     */
    vma->vm_flags |= VM_SOFTDIRTY;

    vma_set_page_prot(vma);

    return addr;

unmap_and_free_vma:
    vma->vm_file = NULL;
    fput(file);

    /* Undo any partial mapping done by a device driver. */
    unmap_region(mm, vma, prev, vma->vm_start, vma->vm_end);
    charged = 0;
    if (vm_flags & VM_SHARED)
        mapping_unmap_writable(file->f_mapping);
allow_write_and_free_vma:
    if (vm_flags & VM_DENYWRITE)
        allow_write_access(file);
free_vma:
    kmem_cache_free(vm_area_cachep, vma);
unacct_error:
    if (charged)
        vm_unacct_memory(charged);
    return error;
}
```
