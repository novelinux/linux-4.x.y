## __do_page_cache_readahead

mapping:文件拥有者的addresss_space对象
filp:文件对象
offset:页面在文件内的偏移量
nr_to_read:完成当前读操作需要的页面数
lookahead_size:异步预读大小

```
/*
 * __do_page_cache_readahead() actually reads a chunk of disk.  It allocates
 * the pages first, then submits them for I/O. This avoids the very bad
 * behaviour which would occur if page allocations are causing VM writeback.
 * We really don't want to intermingle reads and writes like that.
 *
 * Returns the number of pages requested, or the maximum amount of I/O allowed.
 */
unsigned int __do_page_cache_readahead(struct address_space *mapping,
		struct file *filp, pgoff_t offset, unsigned long nr_to_read,
		unsigned long lookahead_size)
{
	struct inode *inode = mapping->host;
	struct page *page;
	unsigned long end_index;	/* The last page we want to read */
	LIST_HEAD(page_pool);
	int page_idx;
	unsigned int nr_pages = 0;
	loff_t isize = i_size_read(inode);
	gfp_t gfp_mask = readahead_gfp_mask(mapping);

	if (isize == 0)
		goto out;

	end_index = ((isize - 1) >> PAGE_SHIFT);

	/*
	 * Preallocate as many pages as we will need.
	 */
	for (page_idx = 0; page_idx < nr_to_read; page_idx++) {
		pgoff_t page_offset = offset + page_idx;

		if (page_offset > end_index)
			break;

		page = xa_load(&mapping->i_pages, page_offset);
		if (page && !xa_is_value(page)) {
			/*
			 * Page already present?  Kick off the current batch of
			 * contiguous pages before continuing with the next
			 * batch.
			 */
			if (nr_pages)
				read_pages(mapping, filp, &page_pool, nr_pages,
						gfp_mask);
			nr_pages = 0;
			continue;
		}

		page = __page_cache_alloc(gfp_mask);
		if (!page)
			break;
		page->index = page_offset;
		list_add(&page->lru, &page_pool);
		if (page_idx == nr_to_read - lookahead_size)
			SetPageReadahead(page);
		nr_pages++;
	}
```

首先预分配一些内存页面,用来存放读取的文件数据。在预读过程中,可能有其他进程已经将某些页面读进内存,检因此在此检查页面是否已经在Cache中。若页面Cache中没有所请求的页面,则分配内存页面,并将页面加入到页面池中。当分配到第nr_to_read ‐ lookahead_size个页面时,就设置该页面标志PG_readahead,以让下次进行异步预读.

### read_pages

```
	/*
	 * Now start the IO.  We ignore I/O errors - if the page is not
	 * uptodate then the caller will launch readpage again, and
	 * will then handle the error.
	 */
	if (nr_pages)
		read_pages(mapping, filp, &page_pool, nr_pages, gfp_mask);
	BUG_ON(!list_empty(&page_pool));
out:
	return nr_pages;
}
```

页面准备好后,调用read_pages()执行I/O操作,从磁盘读取文件数据。

[read_pages](./read_pages.md)