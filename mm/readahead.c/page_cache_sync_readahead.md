## page_cache_sync_readahead

我们先分析page_cache_sync_readahead()函数,顾名思义,就是同步预读一些页面到内存中。
page_cache_sync_readahead()它重新装满当前窗口和前进窗口,并根据预读命中率来更新窗口大小。函数有5个参数:

* mapping: 文件拥有者的addresss_space对象
* ra: 包含此页面的文件file_ra_state描述符
* filp: 文件对象
* offset: 页面在文件内的偏移量
* req_size: 完成当前读操作需要的页面数

```
/**
 * page_cache_sync_readahead - generic file readahead
 * @mapping: address_space which holds the pagecache and I/O vectors
 * @ra: file_ra_state which holds the readahead state
 * @filp: passed on to ->readpage() and ->readpages()
 * @offset: start offset into @mapping, in pagecache page-sized units
 * @req_size: hint: total size of the read which the caller is performing in
 *            pagecache pages
 *
 * page_cache_sync_readahead() should be called when a cache miss happened:
 * it will submit the read.  The readahead logic may decide to piggyback more
 * pages onto the read request if access patterns suggest it will improve
 * performance.
 */
void page_cache_sync_readahead(struct address_space *mapping,
			       struct file_ra_state *ra, struct file *filp,
			       pgoff_t offset, unsigned long req_size)
{
	/* no read-ahead */
	if (!ra->ra_pages)
		return;

	if (blk_cgroup_congested())
		return;

	/* be dumb */
	if (filp && (filp->f_mode & FMODE_RANDOM)) {
		force_page_cache_readahead(mapping, filp, offset, req_size);
		return;
	}

	/* do read-ahead */
	ondemand_readahead(mapping, ra, filp, false, offset, req_size);
}
EXPORT_SYMBOL_GPL(page_cache_sync_readahead);
```