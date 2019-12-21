## find_get_entry

```
/**
 * find_get_entry - find and get a page cache entry
 * @mapping: the address_space to search
 * @offset: the page cache index
 *
 * Looks up the page cache slot at @mapping & @offset.  If there is a
 * page cache page, it is returned with an increased refcount.
 *
 * If the slot holds a shadow entry of a previously evicted page, or a
 * swap entry from shmem/tmpfs, it is returned.
 *
 * Otherwise, %NULL is returned.
 */
struct page *find_get_entry(struct address_space *mapping, pgoff_t offset)
{
	XA_STATE(xas, &mapping->i_pages, offset);
	struct page *head, *page;

	rcu_read_lock();
repeat:
	xas_reset(&xas);
	page = xas_load(&xas);
	if (xas_retry(&xas, page))
		goto repeat;
	/*
	 * A shadow entry of a recently evicted page, or a swap entry from
	 * shmem/tmpfs.  Return it without attempting to raise page count.
	 */
	if (!page || xa_is_value(page))
		goto out;

	head = compound_head(page);
	if (!page_cache_get_speculative(head))
		goto repeat;

	/* The page was split under us? */
	if (compound_head(page) != head) {
		put_page(head);
		goto repeat;
	}

	/*
	 * Has the page moved?
	 * This is part of the lockless pagecache protocol. See
	 * include/linux/pagemap.h for details.
	 */
	if (unlikely(page != xas_reload(&xas))) {
		put_page(head);
		goto repeat;
	}
out:
	rcu_read_unlock();

	return page;
}
EXPORT_SYMBOL(find_get_entry);
```

* xas_load:

[Xarray](../../lib/xarray.c/README.md)