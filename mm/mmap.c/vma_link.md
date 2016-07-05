vma_link
========================================

vma_link函数将新区域合并到该进程现存的数据结构mm_struct中去.

Arguments
----------------------------------------

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
```

__vma_link
----------------------------------------

```
    __vma_link(mm, vma, prev, rb_link, rb_parent);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/__vma_link.md

__vma_link_file
----------------------------------------

__vma_link_file将相关的address_space和映射(如果是文件映射)关联起来.

```
    __vma_link_file(vma);

    if (mapping)
        i_mmap_unlock_write(mapping);

    mm->map_count++;
    validate_mm(mm);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/__vma_link_file.md
