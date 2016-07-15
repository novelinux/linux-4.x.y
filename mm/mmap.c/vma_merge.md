vma_merge
========================================

Comments
----------------------------------------

path: mm/mmap.c
```
/*
 * Given a mapping request (addr,end,vm_flags,file,pgoff), figure out
 * whether that can be merged with its predecessor or its successor.
 * Or both (it neatly fills a hole).
 *
 * In most cases - when called for mmap, brk or mremap - [addr,end) is
 * certain not to be mapped by the time vma_merge is called; but when
 * called for mprotect, it is certain to be already mapped (either at
 * an offset within prev, or at the start of next), and the flags of
 * this area are about to be changed to vm_flags - and the no-change
 * case has already been eliminated.
 *
 * The following mprotect cases have to be considered, where AAAA is
 * the area passed down from mprotect_fixup, never extending beyond one
 * vma, PPPPPP is the prev vma specified, and NNNNNN the next vma after:
 *
 *     AAAA             AAAA                AAAA          AAAA
 *    PPPPPPNNNNNN    PPPPPPNNNNNN    PPPPPPNNNNNN    PPPPNNNNXXXX
 *    cannot merge    might become    might become    might become
 *                    PPNNNNNNNNNN    PPPPPPPPPPNN    PPPPPPPPPPPP 6 or
 *    mmap, brk or    case 4 below    case 5 below    PPPPPPPPXXXX 7 or
 *    mremap move:                                    PPPPNNNNNNNN 8
 *        AAAA
 *    PPPP    NNNN    PPPPPPPPPPPP    PPPPPPPPNNNN    PPPPNNNNNNNN
 *    might become    case 1 below    case 2 below    case 3 below
 *
 * Odd one out? Case 8, because it extends NNNN but needs flags of XXXX:
 * mprotect_fixup updates vm_flags & vm_page_prot on successful return.
 */
```

Arguments
----------------------------------------

```
struct vm_area_struct *vma_merge(struct mm_struct *mm,
            struct vm_area_struct *prev, unsigned long addr,
            unsigned long end, unsigned long vm_flags,
            struct anon_vma *anon_vma, struct file *file,
            pgoff_t pgoff, struct mempolicy *policy,
            struct vm_userfaultfd_ctx vm_userfaultfd_ctx)
{
    pgoff_t pglen = (end - addr) >> PAGE_SHIFT;
    struct vm_area_struct *area, *next;
    int err;
```

* mm: 是相关进程的地址空间实例.
* prev: 是紧接着新分区之前的区域.
* addr: 新区域的开始地址.
* end: 新区域的结束地址.
* vm_flags: 新区域的标志.
* anon_vma: 指向匿名映射区域.
* file: 如果该区域属于一个文件映射，则file是一个指向表示该文件的file实例.
* policy: 只在NUMA系统上需要.

Check flags
----------------------------------------

```
    /*
     * We later require that vma->vm_flags == vm_flags,
     * so this tests vma->vm_flags & VM_SPECIAL, too.
     */
    if (vm_flags & VM_SPECIAL)
        return NULL;
```

Check prev
----------------------------------------

首先检查确定前一个区域的结束地址是否是新区域的起始地址.
倘若如此，内核接下来必须检查两个区域，却表二者的标志和
映射的文件相同,文件映射的内部的偏移量符合连续区域的要求,
两个区域都不能包含匿名映射，而且两个区域彼此兼容.通过
can_vma_merge_after辅助函数完成检查. 将区域与前一个区域
合并的工作看起来如下所示:

```
    if (prev)
        next = prev->vm_next;
    else
        next = mm->mmap;
    area = next;
    if (next && next->vm_end == end)        /* cases 6, 7, 8 */
        next = next->vm_next;

    /*
     * Can it merge with the predecessor?
     */
    if (prev && prev->vm_end == addr &&
            mpol_equal(vma_policy(prev), policy) &&
            can_vma_merge_after(prev, vm_flags,
                        anon_vma, file, pgoff,
                        vm_userfaultfd_ctx)) {
        /*
         * OK, it can.  Can we now merge in the successor as well?
         */
        if (next && end == next->vm_start &&
                mpol_equal(policy, vma_policy(next)) &&
                can_vma_merge_before(next, vm_flags,
                             anon_vma, file,
                             pgoff+pglen,
                             vm_userfaultfd_ctx) &&
                is_mergeable_anon_vma(prev->anon_vma,
                              next->anon_vma, NULL)) {
                            /* cases 1, 6 */
            err = vma_adjust(prev, prev->vm_start,
                next->vm_end, prev->vm_pgoff, NULL);
        } else                    /* cases 2, 5, 7 */
            err = vma_adjust(prev, prev->vm_start,
                end, prev->vm_pgoff, NULL);
        if (err)
            return NULL;
        khugepaged_enter_vma_merge(prev, vm_flags);
        return prev;
    }
```

Check next
----------------------------------------

与前一例的差别是使用can_vma_merge_before来检查两个区域是否可以合并,
替代can_vma_merge_after.如果前一个和后一个区域都可以与当前区域合并,
还必须确认前一个和后一个区域的匿名映射可以合并，然后才能创建包含
这(两个或者三个区域)的第一个单一区域.

```
    /*
     * Can this new request be merged in front of next?
     */
    if (next && end == next->vm_start &&
            mpol_equal(policy, vma_policy(next)) &&
            can_vma_merge_before(next, vm_flags,
                         anon_vma, file, pgoff+pglen,
                         vm_userfaultfd_ctx)) {
        if (prev && addr < prev->vm_end)    /* case 4 */
            err = vma_adjust(prev, prev->vm_start,
                addr, prev->vm_pgoff, NULL);
        else                    /* cases 3, 8 */
            err = vma_adjust(area, addr, next->vm_end,
                next->vm_pgoff - pglen, NULL);
        if (err)
            return NULL;
        khugepaged_enter_vma_merge(area, vm_flags);
        return area;
    }

    return NULL;
}
```
