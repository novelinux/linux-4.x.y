vma_link
========================================

vma_link函数将新区域合并到该进程现存的数据结构mm_struct中去.

path: mm/mmap.c
```
static void vma_link(struct mm_struct *mm, struct vm_area_struct *vma,
            struct vm_area_struct *prev, struct rb_node **rb_link,
            struct rb_node *rb_parent)
{
    struct address_space *mapping = NULL;

    if (vma->vm_file) {
        mapping = vma->vm_file->f_mapping;
        i_mmap_lock_write(mapping);
    }

    __vma_link(mm, vma, prev, rb_link, rb_parent);
    __vma_link_file(vma);

    if (mapping)
        i_mmap_unlock_write(mapping);

    mm->map_count++;
    validate_mm(mm);
}
```

1.__vma_link
----------------------------------------

path: mm/mmap.c
```
static void
__vma_link(struct mm_struct *mm, struct vm_area_struct *vma,
    struct vm_area_struct *prev, struct rb_node **rb_link,
    struct rb_node *rb_parent)
{
    __vma_link_list(mm, vma, prev, rb_parent);
    __vma_link_rb(mm, vma, rb_link, rb_parent);
}
```

### 1.__vma_link_list

将新区域放置到进程管理区域的线性链表上。完成该工作,只需要使用find_vma_links找到的前一个和后一个区域.

### 2.__vma_link_rb

将新区域链接到红黑树的数据结构中.

2.__vma_link_file
----------------------------------------

__vma_link_file将相关的address_space和映射(如果是文件映射)关联起来.

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
        if (unlikely(vma->vm_flags & VM_NONLINEAR))
            vma_nonlinear_insert(vma, &mapping->i_mmap_nonlinear);
        else
            vma_interval_tree_insert(vma, &mapping->i_mmap);
        flush_dcache_mmap_unlock(mapping);
    }
}
```