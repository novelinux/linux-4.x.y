## ondemand_readahead

ondemand_readahead该函数主要根据file_ra_state描述符中的成员变量来执行一些动作。
* (1)首先判断如果是从文件头开始读取的,初始化预读信息。默认设置预读为4个page。
* (2)如果不是文件头,则判断是否连续的读取请求,如果是则扩大预读数量。一般等于上次预读数量x2。
* (3)否则就是随机的读取,不适用预读,只读取sys_read请求的数量。
* (4)然后调用ra_submit提交读取请求。

```
/*
 * A minimal readahead algorithm for trivial sequential/random reads.
 */
static unsigned long
ondemand_readahead(struct address_space *mapping,
		   struct file_ra_state *ra, struct file *filp,
		   bool hit_readahead_marker, pgoff_t offset,
		   unsigned long req_size)
{
	struct backing_dev_info *bdi = inode_to_bdi(mapping->host);
	unsigned long max_pages = ra->ra_pages;
	unsigned long add_pages;
	pgoff_t prev_offset;

	/*
	 * If the request exceeds the readahead window, allow the read to
	 * be up to the optimal hardware IO size
	 */
	if (req_size > max_pages && bdi->io_pages > max_pages)
		max_pages = min(req_size, bdi->io_pages);

	/*
	 * start of file
	 */
	if (!offset)
		goto initial_readahead;

	/*
	 * It's the expected callback offset, assume sequential access.
	 * Ramp up sizes, and push forward the readahead window.
	 */
	if ((offset == (ra->start + ra->size - ra->async_size) ||
	     offset == (ra->start + ra->size))) {
		ra->start += ra->size;
		ra->size = get_next_ra_size(ra, max_pages);
		ra->async_size = ra->size;
		goto readit;
	}

	/*
	 * Hit a marked page without valid readahead state.
	 * E.g. interleaved reads.
	 * Query the pagecache for async_size, which normally equals to
	 * readahead size. Ramp it up and use it as the new readahead size.
	 */
	if (hit_readahead_marker) {
		pgoff_t start;

		rcu_read_lock();
		start = page_cache_next_miss(mapping, offset + 1, max_pages);
		rcu_read_unlock();

		if (!start || start - offset > max_pages)
			return 0;

		ra->start = start;
		ra->size = start - offset;	/* old async_size */
		ra->size += req_size;
		ra->size = get_next_ra_size(ra, max_pages);
		ra->async_size = ra->size;
		goto readit;
	}

	/*
	 * oversize read
	 */
	if (req_size > max_pages)
		goto initial_readahead;

	/*
	 * sequential cache miss
	 * trivial case: (offset - prev_offset) == 1
	 * unaligned reads: (offset - prev_offset) == 0
	 */
	prev_offset = (unsigned long long)ra->prev_pos >> PAGE_SHIFT;
	if (offset - prev_offset <= 1UL)
		goto initial_readahead;

	/*
	 * Query the page cache and look for the traces(cached history pages)
	 * that a sequential stream would leave behind.
	 */
	if (try_context_readahead(mapping, ra, offset, req_size, max_pages))
		goto readit;

	/*
	 * standalone, small random read
	 * Read as is, and do not pollute the readahead state.
	 */
	return __do_page_cache_readahead(mapping, filp, offset, req_size, 0);
```

### initial_readahead

```
initial_readahead:
	ra->start = offset;
	ra->size = get_init_ra_size(req_size, max_pages);
	ra->async_size = ra->size > req_size ? ra->size - req_size : ra->size;
```

### readit

```
readit:
	/*
	 * Will this read hit the readahead marker made by itself?
	 * If so, trigger the readahead marker hit now, and merge
	 * the resulted next readahead window into the current one.
	 * Take care of maximum IO pages as above.
	 */
	if (offset == ra->start && ra->size == ra->async_size) {
		add_pages = get_next_ra_size(ra, max_pages);
		if (ra->size + add_pages <= max_pages) {
			ra->async_size = add_pages;
			ra->size += add_pages;
		} else {
			ra->size = max_pages;
			ra->async_size = max_pages >> 1;
		}
	}

	return ra_submit(ra, mapping, filp);
}
```

get_init_ra_size()计算初始预读窗口大小,get_next_ra_size()计算下一个预读窗口大小。

当进程第一次访问文件并且请求的第一个页面在文件内的偏移量是0时,ondemand_readahead()函数会认为进程会进行顺序访问文件。于是函数从第一个页面开始创建新的当前窗口。当前窗口的初始值大小一般是2的幂次方,通常与进程第一次读取的页面数有关:请求的页面数越多,当前窗口越大,最大值保存在ra->ra_pages中。相反地,进程第一次访问文件,但请求的页面在文件内的偏移量不是0时,内核就认为进程不会进行顺序访问。这样暂时关闭预读功能(设置ra->size的值为-1)。然而内核重新发现顺序访问文件时,就会启用预读,创建新的当前窗口。

若前进窗口(ahead window)不存在,当函数意识到进程在当前窗口进行顺序访问时,就会创建新的前进窗口。前进窗口的起始页面通常是紧邻当前窗口的最后一个页面。前进窗口的大小与当前窗口大小有关。一旦函数发现文件访问不是顺序的(根据前一次的访问),当前窗口和前进窗口就会被清空且预读功能被暂时关闭。当发现顺序访问时,就会重新启用预读。

### ra_submit

[ra_submit](../internal.h/ra_submit.md)