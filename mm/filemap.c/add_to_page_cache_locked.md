## add_to_page_cache_locked

函数有4个参数:
page:页面描述符指针,该页面中有文件数据;
mapping:address_space对象指针;
offset:表示该页在文件的页面索引;
gfp_mask:为基树分配新节点时所使用的分配标志。
将页面插入基树的主体是radix_tree_insert(),这里我们只要清楚是将一个页面(该
页面中的数据是从磁盘读取上来的)插入到页面Cache中就可以了。

```
static int __add_to_page_cache_locked(struct page *page,
				      struct address_space *mapping,
				      pgoff_t offset, gfp_t gfp_mask,
				      void **shadowp)
{
	XA_STATE(xas, &mapping->i_pages, offset);
	int huge = PageHuge(page);
	struct mem_cgroup *memcg;
	int error;
	void *old;

	VM_BUG_ON_PAGE(!PageLocked(page), page);
	VM_BUG_ON_PAGE(PageSwapBacked(page), page);
	mapping_set_update(&xas, mapping);

	if (!huge) {
		error = mem_cgroup_try_charge(page, current->mm,
					      gfp_mask, &memcg, false);
		if (error)
			return error;
	}

	get_page(page);
	page->mapping = mapping;
	page->index = offset;

	do {
		xas_lock_irq(&xas);
		old = xas_load(&xas);
		if (old && !xa_is_value(old))
			xas_set_err(&xas, -EEXIST);
		xas_store(&xas, page);
		if (xas_error(&xas))
			goto unlock;

		if (xa_is_value(old)) {
			mapping->nrexceptional--;
			if (shadowp)
				*shadowp = old;
		}
		mapping->nrpages++;

		/* hugetlb pages do not participate in page cache accounting */
		if (!huge)
			__inc_node_page_state(page, NR_FILE_PAGES);
unlock:
		xas_unlock_irq(&xas);
	} while (xas_nomem(&xas, gfp_mask & GFP_RECLAIM_MASK));

	if (xas_error(&xas))
		goto error;

	if (!huge)
		mem_cgroup_commit_charge(page, memcg, false, false);
	trace_mm_filemap_add_to_page_cache(page);
	return 0;
error:
	page->mapping = NULL;
	/* Leave page->index set: truncation relies upon it */
	if (!huge)
		mem_cgroup_cancel_charge(page, memcg, false);
	put_page(page);
	return xas_error(&xas);
}
```