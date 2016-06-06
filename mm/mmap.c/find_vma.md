find_vma
========================================

find_vma用于在进程虚拟地址空间中查找结束地址在给定地址之后的
第一个区域. 即满足addr < vm_area_struct->vm_end条件的第一个区域.
该函数的参数不仅包括虚拟地址(addr),还包括一个指向mm_struct实例
的指针，后者指定了扫描哪个进程的地址空间.

path: mm/mmap.c
```
/* Look up the first VMA which satisfies  addr < vm_end,  NULL if none. */
struct vm_area_struct *find_vma(struct mm_struct *mm, unsigned long addr)
{
    struct rb_node *rb_node;
    struct vm_area_struct *vma;

    /* Check the cache first. */
    vma = vmacache_find(mm, addr);
    if (likely(vma))
        return vma;

    rb_node = mm->mm_rb.rb_node;
    vma = NULL;

    while (rb_node) {
        struct vm_area_struct *tmp;

        tmp = rb_entry(rb_node, struct vm_area_struct, vm_rb);

        if (tmp->vm_end > addr) {
            vma = tmp;
            if (tmp->vm_start <= addr)
                break;
            rb_node = rb_node->rb_left;
        } else
            rb_node = rb_node->rb_right;
    }

    if (vma)
        vmacache_update(addr, vma);
    return vma;
}
```

* 1.首先调用vmacache_find检查缓存中是否包含所需地址.即：是否该区域的结束地址在目标地址之后，而
    起始地址在目标地址之前.倘若如此，内核立即将指向该区域的vma指针返回.

* 2.如果缓存中未找到这样的区域，则逐步搜索红黑树. rb_node是用于表示树中各个节点的数据结构.
    rb_entry用于从节点取出vm_area_struct实例的首地址. 树的根节点位于mm->mm_rb.rb.node.
    如果相关区域结束地址大于目标地址，而起始地址小于目标地址，内核就找到一个合适的节点，
    可以退出while循环，返回指向vm_area_struct实例的指针，否则，再继续搜索.
* A.如果当前区域结束地址大于目标地址，则从左子节点开始;
* B.如果当前区域结束地址小于等于目标地址，则从右子节点开始.
* C.如果树根节点的子节点为NULL指针，则内核很容易判断何时结束搜索并返回NULL作为错误信息.

* 3.如果找到合适区域，则将其在缓冲区中更新，因为下一次find_vma调用搜索同一个区域中临近
    地址的可能性很高.