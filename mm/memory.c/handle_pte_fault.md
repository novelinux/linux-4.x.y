# handle_pte_fault

handle_pte_fault函数分析缺页异常的原因。pte是指向相关页表项(pte_t)的指针。

path: mm/memory.c
```
/*
 * These routines also need to handle stuff like marking pages dirty
 * and/or accessed for architectures that don't do it in hardware (most
 * RISC architectures).  The early dirtying is also good on the i386.
 *
 * There is also a hook called "update_mmu_cache()" that architectures
 * with external mmu caches can use to update those (ie the Sparc or
 * PowerPC hashed page tables that act as extended TLBs).
 *
 * We enter with non-exclusive mmap_sem (to exclude vma changes,
 * but allow concurrent faults), and pte mapped but not yet locked.
 * We return with pte unmapped and unlocked.
 *
 * The mmap_sem may have been released depending on flags and our
 * return value.  See filemap_fault() and __lock_page_or_retry().
 */
static int handle_pte_fault(struct mm_struct *mm,
             struct vm_area_struct *vma, unsigned long address,
             pte_t *pte, pmd_t *pmd, unsigned int flags)
{
    pte_t entry;
    spinlock_t *ptl;

    /*
     * some architectures can have larger ptes than wordsize,
     * e.g.ppc44x-defconfig has CONFIG_PTE_64BIT=y and CONFIG_32BIT=y,
     * so READ_ONCE or ACCESS_ONCE cannot guarantee atomic accesses.
     * The code below just needs a consistent view for the ifs and
     * we later double check anyway with the ptl lock held. So here
     * a barrier will do.
     */
    entry = *pte;
    barrier();
```

## !pte_present

如果页不在物理内存中，即!pte_present(entry)，则必须区分下面情况:

```
    // pte页表项中的L_PTE_PRESENT位没有置位，说明pte对应的物理页面不存在	
    if (!pte_present(entry)) {
        // pte页表项内容为空，同时pte对应物理页面也不存在
        if (pte_none(entry)) {
            if (vma_is_anonymous(vma))
                return do_anonymous_page(mm, vma, address,
                             pte, pmd, flags);
            else
                return do_fault(mm, vma, address, pte, pmd,
                        flags, entry);
        }
	// -pte对应的物理页面不存在，但是pte页表项不为空，说明该页被交换到swap分区了
        return do_swap_page(mm, vma, address,
                    pte, pmd, flags, entry);
    }
```

### do_anonymous_page

匿名页面缺页中断: 如果没有对应的页表项（page_none），则内核必须从头开始加载该页，对匿名映射称之为按需分配(demand allocation)，对基于文件的映射，则称之为按需调页（demand paging）。内核使用do_anonymous_page返回一个匿名页。

[do_anonymous_page](do_anonymous_page.md)

### do_fault

文件映射缺页中断

[do_fault](do_fault.md)

### do_swap_page

页被交换到swap分区

[do_swap_page](do_swap_page.md)


下面都是物理页面存在的情

## do_numa_page

```
    if (pte_protnone(entry))
        return do_numa_page(mm, vma, address, entry, pte, pmd);

    ptl = pte_lockptr(mm, pmd);
    spin_lock(ptl);
    if (unlikely(!pte_same(*pte, entry)))
        goto unlock;
```

## do_wp_page

```
    if (flags & FAULT_FLAG_WRITE) {
        if (!pte_write(entry)) // 对只读属性的页面产生写异常，触发写时复制缺页中断
            return do_wp_page(mm, vma, address,
                    pte, pmd, ptl, entry);
        entry = pte_mkdirty(entry);
    }
```

[do_wp_page](do_wp_page.md)

## pte_mkyoung

```
    entry = pte_mkyoung(entry);
    if (ptep_set_access_flags(vma, address, pte, entry, flags & FAULT_FLAG_WRITE)) {
        // pte内容发生变化，需要把新的内容写入pte页表项中，并且刷新TLB和cache。
        update_mmu_cache(vma, address, pte);
    } else {
        /*
         * This is needed only for protection faults but the arch code
         * is not yet telling us if this is a protection fault or not.
         * This still avoids useless tlb flushes for .text page faults
         * with threads.
         */
        if (flags & FAULT_FLAG_WRITE)
            flush_tlb_fix_spurious_fault(vma, address);
    }
unlock:
    pte_unmap_unlock(pte, ptl);
    return 0;
}
```