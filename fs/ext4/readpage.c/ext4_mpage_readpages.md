# ext4_mpage_readpages

```
int ext4_mpage_readpages(struct address_space *mapping,
			 struct list_head *pages, struct page *page,
			 unsigned nr_pages)
{
	struct bio *bio = NULL;
	unsigned page_idx;
	sector_t last_block_in_bio = 0;

	struct inode *inode = mapping->host;
	const unsigned blkbits = inode->i_blkbits;
	const unsigned blocks_per_page = PAGE_CACHE_SIZE >> blkbits;
	const unsigned blocksize = 1 << blkbits;
	sector_t block_in_file;
	sector_t last_block;
	sector_t last_block_in_file;
	sector_t blocks[MAX_BUF_PER_PAGE];
	unsigned page_block;
	struct block_device *bdev = inode->i_sb->s_bdev;
	int length;
	unsigned relative_block = 0;
	struct ext4_map_blocks map;

	map.m_pblk = 0;
	map.m_lblk = 0;
	map.m_len = 0;
	map.m_flags = 0;
```

### page_has_buffers

```
	for (page_idx = 0; nr_pages; page_idx++, nr_pages--) {
		int fully_mapped = 1;
		unsigned first_hole = blocks_per_page;

		prefetchw(&page->flags);
		if (pages) {
			page = list_entry(pages->prev, struct page, lru);
			list_del(&page->lru);
			if (add_to_page_cache_lru(page, mapping, page->index,
				  mapping_gfp_constraint(mapping, GFP_KERNEL)))
				goto next_page;
		}
```

for循环,循环次数就是要读取的页面数。

```
		if (page_has_buffers(page))
			goto confused;

		block_in_file = (sector_t)page->index << (PAGE_CACHE_SHIFT - blkbits);
		last_block = block_in_file + nr_pages * blocks_per_page;
		last_block_in_file = (i_size_read(inode) + blocksize - 1) >> blkbits;
		if (last_block > last_block_in_file)
			last_block = last_block_in_file;
		page_block = 0;

		/*
		 * Map blocks using the previous result first.
		 */
		if ((map.m_flags & EXT4_MAP_MAPPED) &&
		    block_in_file > map.m_lblk &&
		    block_in_file < (map.m_lblk + map.m_len)) {
			unsigned map_offset = block_in_file - map.m_lblk;
			unsigned last = map.m_len - map_offset;

			for (relative_block = 0; ; relative_block++) {
				if (relative_block == last) {
					/* needed? */
					map.m_flags &= ~EXT4_MAP_MAPPED;
					break;
				}
				if (page_block == blocks_per_page)
					break;
				blocks[page_block] = map.m_pblk + map_offset +
					relative_block;
				page_block++;
				block_in_file++;
			}
		}

```

首先page_has_buffers检查页面PG_private标志;若该标志已设置,则表明:
* (1)它是缓冲页面(即该页面与一个buffer head链表关联),且已经从磁盘上读取到内存中;
* (2)页面中的块在磁盘上不是相邻的;这样的话,就跳转到,一次读取页面的一个块。

获取块大小blocksize(保存在page->mapping->host->inode->i_blkbits),并且计算访问这个页面所需的两个值:页面中的块数和页面的第一个块(即页内的第一个块相对于文件起始位置的索引)。

* block_in_file: page中的第一个block number。
* last_block: page中最后一个block 大小。
* last_block_in_file: 文件最后一个block大小。
* last_block最终值为本次page读操作的最后一个block大小。

## ext4_map_blocks

[ext4_map_blocks](../inode.c/ext4_map_blocks.md)

```
		/*
		 * Then do more ext4_map_blocks() calls until we are
		 * done with this page.
		 */
		while (page_block < blocks_per_page) {
			if (block_in_file < last_block) {
				map.m_lblk = block_in_file;
				map.m_len = last_block - block_in_file;

				if (ext4_map_blocks(NULL, inode, &map, 0) < 0) {
				set_error_page:
					SetPageError(page);
					zero_user_segment(page, 0,
							  PAGE_CACHE_SIZE);
					unlock_page(page);
					goto next_page;
				}
			}
			if ((map.m_flags & EXT4_MAP_MAPPED) == 0) {
				fully_mapped = 0;
				if (first_hole == blocks_per_page)
					first_hole = page_block;
				page_block++;
				block_in_file++;
				continue;
			}
			if (first_hole != blocks_per_page)
				goto confused;		/* hole -> non-hole */

			/* Contiguous blocks? */
			if (page_block && blocks[page_block-1] != map.m_pblk-1)
				goto confused;
			for (relative_block = 0; ; relative_block++) {
				if (relative_block == map.m_len) {
					/* needed? */
					map.m_flags &= ~EXT4_MAP_MAPPED;
					break;
				} else if (page_block == blocks_per_page)
					break;
				blocks[page_block] = map.m_pblk+relative_block;
				page_block++;
				block_in_file++;
			}
		}
```

* (1) 对于页内的每一个块,调用文件系统相关的get_block函数计算逻辑块数,就是相对于磁盘或分区起始位置的索引。
* (2) 页面里所有块的逻辑块数存放在一个局部数组blocks[]中。
* (3) 检查前面几步中可能出现的异常条件。例如,有些块在磁盘上不相邻,或有些块落入文件空洞中,或某个块缓冲区已经由get_block函数填充。然跳转到confused标号处。

```
		if (first_hole != blocks_per_page) {
			zero_user_segment(page, first_hole << blkbits,
					  PAGE_CACHE_SIZE);
			if (first_hole == 0) {
				SetPageUptodate(page);
				unlock_page(page);
				goto next_page;
			}
		} else if (fully_mapped) {
			SetPageMappedToDisk(page);
		}
```

如果发现文件中有空洞,就将整个page清零,因为文件洞的区域物理层不会真的去磁盘上读取,必须在这里主动清零,否则文件洞区域内容可能随机。该页面也可能是文件的最后一部分数据,于是页面中的部分块在磁盘上没有对应的数据。这样的话,将这些块中都清零。否则设置页面描述符的PG_mappeddisk标志

```
		if (fully_mapped && blocks_per_page == 1 &&
		    !PageUptodate(page) && cleancache_get_page(page) == 0) {
			SetPageUptodate(page);
			goto confused;
		}

		/*
		 * This page will go to BIO.  Do we need to send this
		 * BIO off first?
		 */
		if (bio && (last_block_in_bio != blocks[0] - 1)) {
		submit_and_realloc:
			ext4_submit_bio_read(bio);
			bio = NULL;
		}
		if (bio == NULL) {
			struct ext4_crypto_ctx *ctx = NULL;

			if (ext4_encrypted_inode(inode) &&
			    S_ISREG(inode->i_mode)) {
				ctx = ext4_get_crypto_ctx(inode, GFP_NOFS);
				if (IS_ERR(ctx))
					goto set_error_page;
			}
			bio = bio_alloc(GFP_KERNEL,
				min_t(int, nr_pages, BIO_MAX_PAGES));
			if (!bio) {
				if (ctx)
					ext4_release_crypto_ctx(ctx);
				goto set_error_page;
			}
			bio->bi_bdev = bdev;
			bio->bi_iter.bi_sector = blocks[0] << (blkbits - 9);
			bio->bi_end_io = mpage_end_io;
			bio->bi_private = ctx;
		}
```

调用bio_alloc()分配一个新bio描述符,仅包含一个段(segment);并将成员变量bi_bdev的值初始化为块设备描述符地址,将成员变量bi_sector初始化为页面中第一个块的逻辑块号。这两个值在前面已经计算。设置bio->bi_end_io的值为mpage_end_io,

```
		length = first_hole << blkbits;
		if (bio_add_page(bio, page, length, 0) < length)
			goto submit_and_realloc;

		if (((map.m_flags & EXT4_MAP_BOUNDARY) &&
		     (relative_block == map.m_len)) ||
		    (first_hole != blocks_per_page)) {
			ext4_submit_bio_read(bio);
			bio = NULL;
		} else
			last_block_in_bio = blocks[blocks_per_page - 1];
		goto next_page;
```

若物理块上连续,则尝试页面合并成新的bio。当前page和上一个page的物理block不连续,把上一次的bio给提交,然后重新分配bio。若当前page和上一个page,物理上连续,合并成新的bio后,返回更新后的bio,等待下一次操作。

```
	confused:
		if (bio) {
			ext4_submit_bio_read(bio);
			bio = NULL;
		}
		if (!PageUptodate(page))
			block_read_full_page(page, ext4_get_block);
		else
			unlock_page(page);
	next_page:
		if (pages)
			page_cache_release(page);
	}
	BUG_ON(pages && !list_empty(pages));
	if (bio)
		ext4_submit_bio_read(bio);
	return 0;
}
```

若函数跳转到这里,页面中包含的块在磁盘上是不相邻的。若页面是最新的(设置了PG_update标志),调用unlock_page()来对页面解锁,否则就调用block_read_full_page()来一次读取页面上的一个块。

当I/O数据传输结束时,它就立即被执行。假设没有I/O错误,该函数主要设置页面描述符中的PG_uptodate标志,然后调用unlock_page()来解锁页面,并唤醒在事件上等待的所有进程;最后调用bio_put()销毁bio描述符。在调用submit_bio(),设置数据传输方向到bi_rw标志,更新per-CPU类型变量page_states以记录读扇区数;然后调用generic_make_request()。

[ext4_submit_bio_read](./ext4_submit_bio_read.md)