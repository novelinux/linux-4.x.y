__vma_link_file
========================================

path: mm/mmap.c
```
static void __vma_link_file(struct vm_area_struct *vma)
{
    struct file *file;

    file = vma->vm_file;
    if (file) {
        struct address_space *mapping = file->f_mapping;

        if (vma->vm_flags & VM_DENYWRITE)
            atomic_dec(&file_inode(file)->i_writecount);
        if (vma->vm_flags & VM_SHARED)
            atomic_inc(&mapping->i_mmap_writable);

        flush_dcache_mmap_lock(mapping);
        vma_interval_tree_insert(vma, &mapping->i_mmap);
        flush_dcache_mmap_unlock(mapping);
    }
}
```