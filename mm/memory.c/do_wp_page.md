do_wp_page
========================================

写时复制在do_wp_page中处理.

path: mm/memory.c
```
/*
 * This routine handles present pages, when users try to write
 * to a shared page. It is done by copying the page to a new address
 * and decrementing the shared-page counter for the old page.
 *
 * Note that this routine assumes that the protection checks have been
 * done by the caller (the low-level page fault routine in most cases).
 * Thus we can safely just mark it writable once we've done any necessary
 * COW.
 *
 * We also mark the page dirty at this point even though the page will
 * change only once the write actually happens. This avoids a few races,
 * and potentially makes it more efficient.
 *
 * We enter with non-exclusive mmap_sem (to exclude vma changes,
 * but allow concurrent faults), with pte both mapped and locked.
 * We return with mmap_sem still held, but pte unmapped and unlocked.
 */
static int do_wp_page(struct mm_struct *mm, struct vm_area_struct *vma,
        unsigned long address, pte_t *page_table, pmd_t *pmd,
        spinlock_t *ptl, pte_t orig_pte)
    __releases(ptl)
{
    struct page *old_page;

    old_page = vm_normal_page(vma, address, orig_pte);
    if (!old_page) {
        /*
         * VM_MIXEDMAP !pfn_valid() case, or VM_SOFTDIRTY clear on a
         * VM_PFNMAP VMA.
         *
         * We should not cow pages in a shared writeable mapping.
         * Just mark the pages writable and/or call ops->pfn_mkwrite.
         */
        if ((vma->vm_flags & (VM_WRITE|VM_SHARED)) ==
                     (VM_WRITE|VM_SHARED))
            return wp_pfn_shared(mm, vma, address, page_table, ptl,
                         orig_pte, pmd);

        pte_unmap_unlock(page_table, ptl);
        return wp_page_copy(mm, vma, address, page_table, pmd,
                    orig_pte, old_page);
    }

    /*
     * Take out anonymous pages first, anonymous shared vmas are
     * not dirty accountable.
     */
    if (PageAnon(old_page) && !PageKsm(old_page)) {
        if (!trylock_page(old_page)) {
            page_cache_get(old_page);
            pte_unmap_unlock(page_table, ptl);
            lock_page(old_page);
            page_table = pte_offset_map_lock(mm, pmd, address,
                             &ptl);
            if (!pte_same(*page_table, orig_pte)) {
                unlock_page(old_page);
                pte_unmap_unlock(page_table, ptl);
                page_cache_release(old_page);
                return 0;
            }
            page_cache_release(old_page);
        }
        if (reuse_swap_page(old_page)) {
            /*
             * The page is all ours.  Move it to our anon_vma so
             * the rmap code will not search our parent or siblings.
             * Protected against the rmap code by the page lock.
             */
            page_move_anon_rmap(old_page, vma, address);
            unlock_page(old_page);
            return wp_page_reuse(mm, vma, address, page_table, ptl,
                         orig_pte, old_page, 0, 0);
        }
        unlock_page(old_page);
    } else if (unlikely((vma->vm_flags & (VM_WRITE|VM_SHARED)) ==
                    (VM_WRITE|VM_SHARED))) {
        return wp_page_shared(mm, vma, address, page_table, pmd,
                      ptl, orig_pte, old_page);
    }

    /*
     * Ok, we need to copy. Oh, well..
     */
    page_cache_get(old_page);

    pte_unmap_unlock(page_table, ptl);
    return wp_page_copy(mm, vma, address, page_table, pmd,
                orig_pte, old_page);
}
```