find_vma_links
========================================

find_vma_links函数通过新区域的起始地址和涉及的地址空间(mm_struct),获取如下信息:

Arguments
----------------------------------------

path: mm/mmap.c
```
static int find_vma_links(struct mm_struct *mm, unsigned long addr,
        unsigned long end, struct vm_area_struct **pprev,
        struct rb_node ***rb_link, struct rb_node **rb_parent)
{
    struct rb_node **__rb_link, *__rb_parent, *rb_prev;
```

* pprev - 前一个区域的vm_area_struct实例.
* rb_parent - 由mm->mm_rb描述的红黑树中保存新区域节点的父节点.
* rb_link - 包含该区域自身的(红黑树)叶节点.

```
    __rb_link = &mm->mm_rb.rb_node;
    rb_prev = __rb_parent = NULL;

    while (*__rb_link) {
        struct vm_area_struct *vma_tmp;

        __rb_parent = *__rb_link;
        vma_tmp = rb_entry(__rb_parent, struct vm_area_struct, vm_rb);

        if (vma_tmp->vm_end > addr) {
            /* Fail if an existing vma overlaps the area */
            if (vma_tmp->vm_start < end)
                return -ENOMEM;
            __rb_link = &__rb_parent->rb_left;
        } else {
            rb_prev = __rb_parent;
            __rb_link = &__rb_parent->rb_right;
        }
    }

    *pprev = NULL;
    if (rb_prev)
        *pprev = rb_entry(rb_prev, struct vm_area_struct, vm_rb);
    *rb_link = __rb_link;
    *rb_parent = __rb_parent;
    return 0;
}
```
