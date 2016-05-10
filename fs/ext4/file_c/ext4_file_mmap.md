ext4_file_mmap
========================================

path: fs/ext4/file.c
```
static int ext4_file_mmap(struct file *file, struct vm_area_struct *vma)
{
    file_accessed(file);
    vma->vm_ops = &ext4_file_vm_ops;
    return 0;
}
```

ext4_file_mmap函数的所有工作就是将映射区域的的vm_ops成员设置为ext4_file_vm_ops,
具体实现如下所示:

path: fs/ext4/file.c
```
static const struct vm_operations_struct ext4_file_vm_ops = {
    .fault        = filemap_fault,
    .map_pages    = filemap_map_pages,
    .page_mkwrite = ext4_page_mkwrite,
    .remap_pages  = generic_file_remap_pages,
};
```

其关键元素是failemap_fault, 其具体实现如下所示:

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/filemap_c/filemap_fault.md
