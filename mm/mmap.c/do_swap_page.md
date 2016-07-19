do_swap_page
========================================

path: mm/memory.c
```
/*
 * We enter with non-exclusive mmap_sem (to exclude vma changes,
 * but allow concurrent faults), and pte mapped but not yet locked.
 * We return with pte unmapped and unlocked.
 *
 * We return with the mmap_sem locked or unlocked in the same cases
 * as does filemap_fault().
 */
static int do_swap_page(struct mm_struct *mm, struct vm_area_struct *vma,
        unsigned long address, pte_t *page_table, pmd_t *pmd,
        unsigned int flags, pte_t orig_pte)
{
    spinlock_t *ptl;
    struct page *page, *swapcache;
    struct mem_cgroup *memcg;
    swp_entry_t entry;
    pte_t pte;
    int locked;
    int exclusive = 0;
    int ret = 0;

    if (!pte_unmap_same(mm, pmd, page_table, orig_pte))
        goto out;

    entry = pte_to_swp_entry(orig_pte);
    if (unlikely(non_swap_entry(entry))) {
        if (is_migration_entry(entry)) {
            migration_entry_wait(mm, pmd, address);
        } else if (is_hwpoison_entry(entry)) {
            ret = VM_FAULT_HWPOISON;
        } else {
            print_bad_pte(vma, address, orig_pte, NULL);
            ret = VM_FAULT_SIGBUS;
        }
        goto out;
    }
    delayacct_set_flag(DELAYACCT_PF_SWAPIN);
    page = lookup_swap_cache(entry);
    if (!page) {
        page = swapin_readahead(entry,
                    GFP_HIGHUSER_MOVABLE, vma, address);
        if (!page) {
            /*
             * Back out if somebody else faulted in this pte
             * while we released the pte lock.
             */
            page_table = pte_offset_map_lock(mm, pmd, address, &ptl);
            if (likely(pte_same(*page_table, orig_pte)))
                ret = VM_FAULT_OOM;
            delayacct_clear_flag(DELAYACCT_PF_SWAPIN);
            goto unlock;
        }

        /* Had to read the page from swap area: Major fault */
        ret = VM_FAULT_MAJOR;
        count_vm_event(PGMAJFAULT);
        mem_cgroup_count_vm_event(mm, PGMAJFAULT);
    } else if (PageHWPoison(page)) {
        /*
         * hwpoisoned dirty swapcache pages are kept for killing
         * owner processes (which may be unknown at hwpoison time)
         */
        ret = VM_FAULT_HWPOISON;
        delayacct_clear_flag(DELAYACCT_PF_SWAPIN);
        swapcache = page;
        goto out_release;
    }

    swapcache = page;
    locked = lock_page_or_retry(page, mm, flags);

    delayacct_clear_flag(DELAYACCT_PF_SWAPIN);
    if (!locked) {
        ret |= VM_FAULT_RETRY;
        goto out_release;
    }

    /*
     * Make sure try_to_free_swap or reuse_swap_page or swapoff did not
     * release the swapcache from under us.  The page pin, and pte_same
     * test below, are not enough to exclude that.  Even if it is still
     * swapcache, we need to check that the page's swap has not changed.
     */
    if (unlikely(!PageSwapCache(page) || page_private(page) != entry.val))
        goto out_page;

    page = ksm_might_need_to_copy(page, vma, address);
    if (unlikely(!page)) {
        ret = VM_FAULT_OOM;
        page = swapcache;
        goto out_page;
    }

    if (mem_cgroup_try_charge(page, mm, GFP_KERNEL, &memcg)) {
        ret = VM_FAULT_OOM;
        goto out_page;
    }

    /*
     * Back out if somebody else already faulted in this pte.
     */
    page_table = pte_offset_map_lock(mm, pmd, address, &ptl);
    if (unlikely(!pte_same(*page_table, orig_pte)))
        goto out_nomap;

    if (unlikely(!PageUptodate(page))) {
        ret = VM_FAULT_SIGBUS;
        goto out_nomap;
    }

    /*
     * The page isn't present yet, go ahead with the fault.
     *
     * Be careful about the sequence of operations here.
     * To get its accounting right, reuse_swap_page() must be called
     * while the page is counted on swap but not yet in mapcount i.e.
     * before page_add_anon_rmap() and swap_free(); try_to_free_swap()
     * must be called after the swap_free(), or it will never succeed.
     */

    inc_mm_counter_fast(mm, MM_ANONPAGES);
    dec_mm_counter_fast(mm, MM_SWAPENTS);
    pte = mk_pte(page, vma->vm_page_prot);
    if ((flags & FAULT_FLAG_WRITE) && reuse_swap_page(page)) {
        pte = maybe_mkwrite(pte_mkdirty(pte), vma);
        flags &= ~FAULT_FLAG_WRITE;
        ret |= VM_FAULT_WRITE;
        exclusive = 1;
    }
    flush_icache_page(vma, page);
    if (pte_swp_soft_dirty(orig_pte))
        pte = pte_mksoft_dirty(pte);
    set_pte_at(mm, address, page_table, pte);
    if (page == swapcache) {
        do_page_add_anon_rmap(page, vma, address, exclusive);
        mem_cgroup_commit_charge(page, memcg, true);
    } else { /* ksm created a completely new copy */
        page_add_new_anon_rmap(page, vma, address);
        mem_cgroup_commit_charge(page, memcg, false);
        lru_cache_add_active_or_unevictable(page, vma);
    }

    swap_free(entry);
    if (vm_swap_full() || (vma->vm_flags & VM_LOCKED) || PageMlocked(page))
        try_to_free_swap(page);
    unlock_page(page);
    if (page != swapcache) {
        /*
         * Hold the lock to avoid the swap entry to be reused
         * until we take the PT lock for the pte_same() check
         * (to avoid false positives from pte_same). For
         * further safety release the lock after the swap_free
         * so that the swap count won't change under a
         * parallel locked swapcache.
         */
        unlock_page(swapcache);
        page_cache_release(swapcache);
    }

    if (flags & FAULT_FLAG_WRITE) {
        ret |= do_wp_page(mm, vma, address, page_table, pmd, ptl, pte);
        if (ret & VM_FAULT_ERROR)
            ret &= VM_FAULT_ERROR;
        goto out;
    }

    /* No need to invalidate - it was non-present before */
    update_mmu_cache(vma, address, page_table);
unlock:
    pte_unmap_unlock(page_table, ptl);
out:
    return ret;
out_nomap:
    mem_cgroup_cancel_charge(page, memcg);
    pte_unmap_unlock(page_table, ptl);
out_page:
    unlock_page(page);
out_release:
    page_cache_release(page);
    if (page != swapcache) {
        unlock_page(swapcache);
        page_cache_release(swapcache);
    }
    return ret;
}
```