__handle_mm_fault
========================================

Arguments
----------------------------------------

path: mm/memory.c
```
/*
 * By the time we get here, we already hold the mm semaphore
 *
 * The mmap_sem may have been released depending on flags and our
 * return value.  See filemap_fault() and __lock_page_or_retry().
 */
static int __handle_mm_fault(struct mm_struct *mm, struct vm_area_struct *vma,
                 unsigned long address, unsigned int flags)
{
    pgd_t *pgd;
    pud_t *pud;
    pmd_t *pmd;
    pte_t *pte;

    if (unlikely(is_vm_hugetlb_page(vma)))
        return hugetlb_fault(mm, vma, address, flags);

    pgd = pgd_offset(mm, address);
    pud = pud_alloc(mm, pgd, address);
    if (!pud)
        return VM_FAULT_OOM;
    pmd = pmd_alloc(mm, pud, address);
    if (!pmd)
        return VM_FAULT_OOM;
    if (pmd_none(*pmd) && transparent_hugepage_enabled(vma)) {
        int ret = create_huge_pmd(mm, vma, address, pmd, flags);
        if (!(ret & VM_FAULT_FALLBACK))
            return ret;
    } else {
        pmd_t orig_pmd = *pmd;
        int ret;

        barrier();
        if (pmd_trans_huge(orig_pmd)) {
            unsigned int dirty = flags & FAULT_FLAG_WRITE;

            /*
             * If the pmd is splitting, return and retry the
             * the fault.  Alternative: wait until the split
             * is done, and goto retry.
             */
            if (pmd_trans_splitting(orig_pmd))
                return 0;

            if (pmd_protnone(orig_pmd))
                return do_huge_pmd_numa_page(mm, vma, address,
                                 orig_pmd, pmd);

            if (dirty && !pmd_write(orig_pmd)) {
                ret = wp_huge_pmd(mm, vma, address, pmd,
                            orig_pmd, flags);
                if (!(ret & VM_FAULT_FALLBACK))
                    return ret;
            } else {
                huge_pmd_set_accessed(mm, vma, address, pmd,
                              orig_pmd, dirty);
                return 0;
            }
        }
    }

    /*
     * Use __pte_alloc instead of pte_alloc_map, because we can't
     * run pte_offset_map on the pmd, if an huge pmd could
     * materialize from under us from a different thread.
     */
    if (unlikely(pmd_none(*pmd)) &&
        unlikely(__pte_alloc(mm, vma, pmd, address)))
        return VM_FAULT_OOM;
    /* if an huge pmd materialized from under us just retry later */
    if (unlikely(pmd_trans_huge(*pmd)))
        return 0;
    /*
     * A regular pmd is established and it can't morph into a huge pmd
     * from under us anymore at this point because we hold the mmap_sem
     * read mode and khugepaged takes it in write mode. So now it's
     * safe to run pte_offset_map().
     */
    pte = pte_offset_map(pmd, address);
```

handle_pte_fault
----------------------------------------

```
    return handle_pte_fault(mm, vma, address, pte, pmd, flags);
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/memory.c/handle_pte_fault.md
