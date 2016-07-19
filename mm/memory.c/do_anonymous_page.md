do_anonymous_page
========================================

对于没有关联到文件作为后备存储器的页，需要调用do_anonymous_page进行映射。
除了无需向页读入数据之外，该过程几乎与映射基于文件的数据没什么不同。
在highmem内存域建立一个新页，并清空其内容。接下来将页加入到进程的页表，并更新高速缓存或者MMU。

path: mm/memory.c
```
/*
 * We enter with non-exclusive mmap_sem (to exclude vma changes,
 * but allow concurrent faults), and pte mapped but not yet locked.
 * We return with mmap_sem still held, but pte unmapped and unlocked.
 */
static int do_anonymous_page(struct mm_struct *mm, struct vm_area_struct *vma,
        unsigned long address, pte_t *page_table, pmd_t *pmd,
        unsigned int flags)
{
    struct mem_cgroup *memcg;
    struct page *page;
    spinlock_t *ptl;
    pte_t entry;

    pte_unmap(page_table);

    /* File mapping without ->vm_ops ? */
    if (vma->vm_flags & VM_SHARED)
        return VM_FAULT_SIGBUS;

    /* Check if we need to add a guard page to the stack */
    if (check_stack_guard_page(vma, address) < 0)
        return VM_FAULT_SIGSEGV;

    /* Use the zero-page for reads */
    if (!(flags & FAULT_FLAG_WRITE) && !mm_forbids_zeropage(mm)) {
        entry = pte_mkspecial(pfn_pte(my_zero_pfn(address),
                        vma->vm_page_prot));
        page_table = pte_offset_map_lock(mm, pmd, address, &ptl);
        if (!pte_none(*page_table))
            goto unlock;
        /* Deliver the page fault to userland, check inside PT lock */
        if (userfaultfd_missing(vma)) {
            pte_unmap_unlock(page_table, ptl);
            return handle_userfault(vma, address, flags,
                        VM_UFFD_MISSING);
        }
        goto setpte;
    }

    /* Allocate our own private page. */
    if (unlikely(anon_vma_prepare(vma)))
        goto oom;
    page = alloc_zeroed_user_highpage_movable(vma, address);
    if (!page)
        goto oom;

    if (mem_cgroup_try_charge(page, mm, GFP_KERNEL, &memcg))
        goto oom_free_page;

    /*
     * The memory barrier inside __SetPageUptodate makes sure that
     * preceeding stores to the page contents become visible before
     * the set_pte_at() write.
     */
    __SetPageUptodate(page);

    entry = mk_pte(page, vma->vm_page_prot);
    if (vma->vm_flags & VM_WRITE)
        entry = pte_mkwrite(pte_mkdirty(entry));

    page_table = pte_offset_map_lock(mm, pmd, address, &ptl);
    if (!pte_none(*page_table))
        goto release;

    /* Deliver the page fault to userland, check inside PT lock */
    if (userfaultfd_missing(vma)) {
        pte_unmap_unlock(page_table, ptl);
        mem_cgroup_cancel_charge(page, memcg);
        page_cache_release(page);
        return handle_userfault(vma, address, flags,
                    VM_UFFD_MISSING);
    }

    inc_mm_counter_fast(mm, MM_ANONPAGES);
    page_add_new_anon_rmap(page, vma, address);
    mem_cgroup_commit_charge(page, memcg, false);
    lru_cache_add_active_or_unevictable(page, vma);
setpte:
    set_pte_at(mm, address, page_table, entry);

    /* No need to invalidate - it was non-present before */
    update_mmu_cache(vma, address, page_table);
unlock:
    pte_unmap_unlock(page_table, ptl);
    return 0;
release:
    mem_cgroup_cancel_charge(page, memcg);
    page_cache_release(page);
    goto unlock;
oom_free_page:
    page_cache_release(page);
oom:
    return VM_FAULT_OOM;
}
```