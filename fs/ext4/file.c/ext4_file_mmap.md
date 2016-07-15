ext4_file_mmap
========================================

path: fs/ext4/file.c
```
static int ext4_file_mmap(struct file *file, struct vm_area_struct *vma)
{
    struct inode *inode = file->f_mapping->host;

    if (ext4_encrypted_inode(inode)) {
        int err = ext4_get_encryption_info(inode);
        if (err)
            return 0;
        if (ext4_encryption_info(inode) == NULL)
            return -ENOKEY;
    }
    file_accessed(file);
    if (IS_DAX(file_inode(file))) {
        vma->vm_ops = &ext4_dax_vm_ops;
        vma->vm_flags |= VM_MIXEDMAP | VM_HUGEPAGE;
    } else {
        vma->vm_ops = &ext4_file_vm_ops;
    }
    return 0;
}
```
