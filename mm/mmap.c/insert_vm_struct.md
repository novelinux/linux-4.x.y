insert_vm_struct
========================================

insert_vm_struct是内核用于插入新区域的标准函数.
其执行流程如下所示:

path: mm/mmap.c
```
/* Insert vm structure into process list sorted by address
 * and into the inode's i_mmap tree.  If vm_file is non-NULL
 * then i_mmap_rwsem is taken here.
 */
int insert_vm_struct(struct mm_struct *mm, struct vm_area_struct *vma)
{
    struct vm_area_struct *prev;
    struct rb_node **rb_link, *rb_parent;

    /*
     * The vm_pgoff of a purely anonymous vma should be irrelevant
     * until its first write fault, when page's anon_vma and index
     * are set.  But now set the vm_pgoff it will almost certainly
     * end up with (unless mremap moves it elsewhere before that
     * first wfault), so /proc/pid/maps tells a consistent story.
     *
     * By setting it to reflect the virtual start address of the
     * vma, merges and splits can happen in a seamless way, just
     * using the existing file pgoff checks and manipulations.
     * Similarly in do_mmap_pgoff and in do_brk.
     */
    if (!vma->vm_file) {
        BUG_ON(vma->anon_vma);
        vma->vm_pgoff = vma->vm_start >> PAGE_SHIFT;
    }
    if (find_vma_links(mm, vma->vm_start, vma->vm_end,
               &prev, &rb_link, &rb_parent))
        return -ENOMEM;
    if ((vma->vm_flags & VM_ACCOUNT) &&
         security_vm_enough_memory_mm(mm, vma_pages(vma)))
        return -ENOMEM;

    vma_link(mm, vma, prev, rb_link, rb_parent);
    return 0;
}
```

1.设置vma->vm_pgoff
----------------------------------------

如果vma描述的区域不是用来映射一个文件，那么设置vma描述的区域的偏移量vm_pgoff，
偏移量的单位是页而不是字节.

2.find_vma_links
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap_c/find_vma_links.md

3.vma_link
----------------------------------------

在通过find_vma_links找到足够的信息后，接下来调用vma_link函数将新区域合并到该进程现存
的数据结构中去.

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap_c/vma_link.md
