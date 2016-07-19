handle_pte_fault
========================================

handle_pte_fault函数分析缺页异常的原因。pte是指向相关页表项(pte_t)的指针。

Arguments
----------------------------------------

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

!pte_present
----------------------------------------

```
    if (!pte_present(entry)) {
        if (pte_none(entry)) {
            if (vma_is_anonymous(vma))
                return do_anonymous_page(mm, vma, address,
                             pte, pmd, flags);
            else
                return do_fault(mm, vma, address, pte, pmd,
                        flags, entry);
        }
        return do_swap_page(mm, vma, address,
                    pte, pmd, flags, entry);
    }
```

如果页不在物理内存中，即!pte_present(entry)，则必须区分下面情况:

### do_anonymous_page

如果没有对应的页表项（page_none），则内核必须从头开始加载该页，对匿名映射
称之为按需分配(demand allocation)，对基于文件的映射，则称之为按需调页（demand paging）。
内核使用do_anonymous_page返回一个匿名页。

https://github.com/novelinux/linux-4.x.y/blob/master/mm/memory.c/do_anonymous_page.md

### do_fault

https://github.com/novelinux/linux-4.x.y/blob/master/mm/memory.c/do_fault.md

### do_swap_page

https://github.com/novelinux/linux-4.x.y/blob/master/mm/memory.c/do_swap_page.md

do_numa_page
----------------------------------------

```
    if (pte_protnone(entry))
        return do_numa_page(mm, vma, address, entry, pte, pmd);

    ptl = pte_lockptr(mm, pmd);
    spin_lock(ptl);
    if (unlikely(!pte_same(*pte, entry)))
        goto unlock;
```

do_wp_page
----------------------------------------

```
    if (flags & FAULT_FLAG_WRITE) {
        if (!pte_write(entry))
            return do_wp_page(mm, vma, address,
                    pte, pmd, ptl, entry);
        entry = pte_mkdirty(entry);
    }
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/memory.c/do_wp_page.md

pte_mkyoung
----------------------------------------

```
    entry = pte_mkyoung(entry);
    if (ptep_set_access_flags(vma, address, pte, entry, flags & FAULT_FLAG_WRITE)) {
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