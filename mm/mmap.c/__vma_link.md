__vma_link
========================================

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

__vma_link_list
----------------------------------------

将新区域放置到进程管理区域的线性链表上。完成该工作,只需要使用find_vma_links
找到的前一个和后一个区域.

__vma_link_rb
----------------------------------------

将新区域链接到红黑树的数据结构中.
