## delete_from_page_cache

```
/*
 * Lock ordering:
 *
 *  ->i_mmap_rwsem		(truncate_pagecache)
 *    ->private_lock		(__free_pte->__set_page_dirty_buffers)
 *      ->swap_lock		(exclusive_swap_page, others)
 *        ->i_pages lock
 *
 *  ->i_mutex
 *    ->i_mmap_rwsem		(truncate->unmap_mapping_range)
 *
 *  ->mmap_sem
 *    ->i_mmap_rwsem
 *      ->page_table_lock or pte_lock	(various, mainly in memory.c)
 *        ->i_pages lock	(arch-dependent flush_dcache_mmap_lock)
 *
 *  ->mmap_sem
 *    ->lock_page		(access_process_vm)
 *
 *  ->i_mutex			(generic_perform_write)
 *    ->mmap_sem		(fault_in_pages_readable->do_page_fault)
 *
 *  bdi->wb.list_lock
 *    sb_lock			(fs/fs-writeback.c)
 *    ->i_pages lock		(__sync_single_inode)
 *
 *  ->i_mmap_rwsem
 *    ->anon_vma.lock		(vma_adjust)
 *
 *  ->anon_vma.lock
 *    ->page_table_lock or pte_lock	(anon_vma_prepare and various)
 *
 *  ->page_table_lock or pte_lock
 *    ->swap_lock		(try_to_unmap_one)
 *    ->private_lock		(try_to_unmap_one)
 *    ->i_pages lock		(try_to_unmap_one)
 *    ->zone_lru_lock(zone)	(follow_page->mark_page_accessed)
 *    ->zone_lru_lock(zone)	(check_pte_range->isolate_lru_page)
 *    ->private_lock		(page_remove_rmap->set_page_dirty)
 *    ->i_pages lock		(page_remove_rmap->set_page_dirty)
 *    bdi.wb->list_lock		(page_remove_rmap->set_page_dirty)
 *    ->inode->i_lock		(page_remove_rmap->set_page_dirty)
 *    ->memcg->move_lock	(page_remove_rmap->lock_page_memcg)
 *    bdi.wb->list_lock		(zap_pte_range->set_page_dirty)
 *    ->inode->i_lock		(zap_pte_range->set_page_dirty)
 *    ->private_lock		(zap_pte_range->__set_page_dirty_buffers)
 *
 * ->i_mmap_rwsem
 *   ->tasklist_lock            (memory_failure, collect_procs_ao)
 */

static void page_cache_delete(struct address_space *mapping,
				   struct page *page, void *shadow)
{
	XA_STATE(xas, &mapping->i_pages, page->index);
	unsigned int nr = 1;

	mapping_set_update(&xas, mapping);

	/* hugetlb pages are represented by a single entry in the xarray */
	if (!PageHuge(page)) {
		xas_set_order(&xas, page->index, compound_order(page));
		nr = 1U << compound_order(page);
	}

	VM_BUG_ON_PAGE(!PageLocked(page), page);
	VM_BUG_ON_PAGE(PageTail(page), page);
	VM_BUG_ON_PAGE(nr != 1 && shadow, page);

	xas_store(&xas, shadow);
	xas_init_marks(&xas);

	page->mapping = NULL;
	/* Leave page->index set: truncation lookup relies upon it */

	if (shadow) {
		mapping->nrexceptional += nr;
		/*
		 * Make sure the nrexceptional update is committed before
		 * the nrpages update so that final truncate racing
		 * with reclaim does not see both counters 0 at the
		 * same time and miss a shadow entry.
		 */
		smp_wmb();
	}
	mapping->nrpages -= nr;
}

/*
 * Delete a page from the page cache and free it. Caller has to make
 * sure the page is locked and that nobody else uses it - or that usage
 * is safe.  The caller must hold the i_pages lock.
 */
void __delete_from_page_cache(struct page *page, void *shadow)
{
	struct address_space *mapping = page->mapping;

	trace_mm_filemap_delete_from_page_cache(page);

	unaccount_page_cache_page(mapping, page);
	page_cache_delete(mapping, page, shadow);
}

static void page_cache_free_page(struct address_space *mapping,
				struct page *page)
{
	void (*freepage)(struct page *);

	freepage = mapping->a_ops->freepage;
	if (freepage)
		freepage(page);

	if (PageTransHuge(page) && !PageHuge(page)) {
		page_ref_sub(page, HPAGE_PMD_NR);
		VM_BUG_ON_PAGE(page_count(page) <= 0, page);
	} else {
		put_page(page);
	}
}

/**
 * delete_from_page_cache - delete page from page cache
 * @page: the page which the kernel is trying to remove from page cache
 *
 * This must be called only on pages that have been verified to be in the page
 * cache and locked.  It will never put the page into the free list, the caller
 * has a reference on the page.
 */
void delete_from_page_cache(struct page *page)
{
	struct address_space *mapping = page_mapping(page);
	unsigned long flags;

	BUG_ON(!PageLocked(page));
	xa_lock_irqsave(&mapping->i_pages, flags);
	__delete_from_page_cache(page, NULL);
	xa_unlock_irqrestore(&mapping->i_pages, flags);

	page_cache_free_page(mapping, page);
}
EXPORT_SYMBOL(delete_from_page_cache);
```