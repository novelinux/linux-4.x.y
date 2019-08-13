# ext4_writepages

```
static int ext4_writepages(struct address_space *mapping,
			   struct writeback_control *wbc)
{
	pgoff_t	writeback_index = 0;
	long nr_to_write = wbc->nr_to_write;
	int range_whole = 0;
	int cycled = 1;
	handle_t *handle = NULL;
	struct mpage_da_data mpd;
	struct inode *inode = mapping->host;
	int needed_blocks, rsv_blocks = 0, ret = 0;
	struct ext4_sb_info *sbi = EXT4_SB(mapping->host->i_sb);
	bool done;
	struct blk_plug plug;
	bool give_up_on_write = false;
```

判断是否有页需要回写，如果地址空间中没有映射页或者radix tree中没有设置PAGECACHE_TAG_DIRTY标识（即无脏页，该标识会在__set_page_dirty函数中对脏的数据块设置），那就直接退出即可。然后判断当前文件系统的日志模式，如果是journal模式（数据块和元数据块都需要写jbd2日志），将交由write_cache_pages函数执行回写，由于默认使用的是order日志模式，所以略过，继续往下分析。

```
	trace_ext4_writepages(inode, wbc);

	/*
	 * No pages to write? This is mainly a kludge to avoid starting
	 * a transaction for special inodes like journal inode on last iput()
	 * because that could violate lock ordering on umount
	 */
	if (!mapping->nrpages || !mapping_tagged(mapping, PAGECACHE_TAG_DIRTY))
		goto out_writepages;

	if (ext4_should_journal_data(inode)) {
		struct blk_plug plug;

		blk_start_plug(&plug);
		ret = write_cache_pages(mapping, wbc, __writepage, mapping);
		blk_finish_plug(&plug);
		goto out_writepages;
	}
```

接下处理dioread_nolock特性， 该特性会在文件写buffer前分配未初始化的extent，等待写IO完成后才会对extent进行初始化，以此可以免去加解inode mutext锁，从而来达到加速写操作的目的。该特性只对启用了extent属性的文件有用，且不支持journal日志模式。若启用了该特性则需要在日志中设置保留块，默认文件系统的块大小为4KB，那这里将指定保留块为2个。

```
	/*
	 * If the filesystem has aborted, it is read-only, so return
	 * right away instead of dumping stack traces later on that
	 * will obscure the real source of the problem.  We test
	 * EXT4_MF_FS_ABORTED instead of sb->s_flag's MS_RDONLY because
	 * the latter could be true if the filesystem is mounted
	 * read-only, and in that case, ext4_writepages should
	 * *never* be called, so if that ever happens, we would want
	 * the stack trace.
	 */
	if (unlikely(sbi->s_mount_flags & EXT4_MF_FS_ABORTED)) {
		ret = -EROFS;
		goto out_writepages;
	}

	if (ext4_should_dioread_nolock(inode)) {
		/*
		 * We may need to convert up to one extent per block in
		 * the page and we may dirty the inode.
		 */
		rsv_blocks = 1 + (PAGE_CACHE_SIZE >> inode->i_blkbits);
	}
```

接下来处理inline data特性，该特性是对于小文件的，它的数据内容足以保存在inode block中

```
	/*
	 * If we have inline data and arrive here, it means that
	 * we will soon create the block for the 1st page, so
	 * we'd better clear the inline data here.
	 */
	if (ext4_has_inline_data(inode)) {
		/* Just inode will be modified... */
		handle = ext4_journal_start(inode, EXT4_HT_INODE, 1);
		if (IS_ERR(handle)) {
			ret = PTR_ERR(handle);
			goto out_writepages;
		}
		BUG_ON(ext4_test_inode_state(inode,
				EXT4_STATE_MAY_INLINE_DATA));
		ext4_destroy_inline_data(handle, inode);
		ext4_journal_stop(handle);
	}
```

接下来进行一些标识位的判断，其中range_whole置位表示写整个文件；然后初始化struct mpage_da_data mpd结构体，在当前的非周期写的情况下设置需要写的first_page和last_page，然后初始化mpd结构体的inode、wbc和io_submit这三个字段，然后跳转到retry标号处开始执行。


```
	if (wbc->range_start == 0 && wbc->range_end == LLONG_MAX)
		range_whole = 1;

	if (wbc->range_cyclic) {
		writeback_index = mapping->writeback_index;
		if (writeback_index)
			cycled = 0;
		mpd.first_page = writeback_index;
		mpd.last_page = -1;
	} else {
		mpd.first_page = wbc->range_start >> PAGE_CACHE_SHIFT;
		mpd.last_page = wbc->range_end >> PAGE_CACHE_SHIFT;
	}

	mpd.inode = inode;
	mpd.wbc = wbc;
	ext4_io_submit_init(&mpd.io_submit, wbc);
```

这里的tag_pages_for_writeback函数需要关注一下，它将address_mapping的radix tree中已经设置了PAGECACHE_TAG_DIRTY标识的节点设置上PAGECACHE_TAG_TOWRITE标识，表示开始回写，后文中的等待结束__filemap_fdatawrite_range函数会判断该标识。接下来进入一个大循环，逐一处理需要回写的数据页。

该循环中的调用流程非常复杂，这里简单描述一下：首先调用ext4_da_writepages_trans_blocks计算extext所需要使用的block数量，然后调用ext4_journal_start_with_reserve启动一个新的日志handle，需要的block数量和保留block数量通过needed_blocks和rsv_blocks给出；然后调用mpage_prepare_extent_to_map和mpage_map_and_submit_extent函数，它将遍历查找wbc中的PAGECACHE_TAG_TOWRITE为标记的节点，对其中已经映射的赃页直接下发IO，对没有映射的则计算需要映射的页要使用的extent并进行映射；随后调用ext4_io_submit下发bio，最后调用ext4_journal_stop结束本次handle。


```
retry:
	if (wbc->sync_mode == WB_SYNC_ALL || wbc->tagged_writepages)
		tag_pages_for_writeback(mapping, mpd.first_page, mpd.last_page);
	done = false;
	blk_start_plug(&plug);
	while (!done && mpd.first_page <= mpd.last_page) {
		/* For each extent of pages we use new io_end */
		mpd.io_submit.io_end = ext4_init_io_end(inode, GFP_KERNEL);
		if (!mpd.io_submit.io_end) {
			ret = -ENOMEM;
			break;
		}

		/*
		 * We have two constraints: We find one extent to map and we
		 * must always write out whole page (makes a difference when
		 * blocksize < pagesize) so that we don't block on IO when we
		 * try to write out the rest of the page. Journalled mode is
		 * not supported by delalloc.
		 */
		BUG_ON(ext4_should_journal_data(inode));
		needed_blocks = ext4_da_writepages_trans_blocks(inode);

		/* start a new transaction */
		handle = ext4_journal_start_with_reserve(inode,
				EXT4_HT_WRITE_PAGE, needed_blocks, rsv_blocks);
		if (IS_ERR(handle)) {
			ret = PTR_ERR(handle);
			ext4_msg(inode->i_sb, KERN_CRIT, "%s: jbd2_start: "
			       "%ld pages, ino %lu; err %d", __func__,
				wbc->nr_to_write, inode->i_ino, ret);
			/* Release allocated io_end */
			ext4_put_io_end(mpd.io_submit.io_end);
			break;
		}

		trace_ext4_da_write_pages(inode, mpd.first_page, mpd.wbc);
```

## mpage_prepare_extent_to_map

```
		ret = mpage_prepare_extent_to_map(&mpd);
		if (!ret) {
			if (mpd.map.m_len)
				ret = mpage_map_and_submit_extent(handle, &mpd,
					&give_up_on_write);
			else {
				/*
				 * We scanned the whole range (or exhausted
				 * nr_to_write), submitted what was mapped and
				 * didn't find anything needing mapping. We are
				 * done.
				 */
				done = true;
			}
		}
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/inode.c/mpage_prepare_extent_to_map.md

## ext4_io_submit

```
		/*
		 * Caution: If the handle is synchronous,
		 * ext4_journal_stop() can wait for transaction commit
		 * to finish which may depend on writeback of pages to
		 * complete or on page lock to be released.  In that
		 * case, we have to wait until after after we have
		 * submitted all the IO, released page locks we hold,
		 * and dropped io_end reference (for extent conversion
		 * to be able to complete) before stopping the handle.
		 */
		if (!ext4_handle_valid(handle) || handle->h_sync == 0) {
			ext4_journal_stop(handle);
			handle = NULL;
		}
		/* Submit prepared bio */
		ext4_io_submit(&mpd.io_submit);
		/* Unlock pages we didn't use */
		mpage_release_unused_pages(&mpd, give_up_on_write);
		/*
		 * Drop our io_end reference we got from init. We have
		 * to be careful and use deferred io_end finishing if
		 * we are still holding the transaction as we can
		 * release the last reference to io_end which may end
		 * up doing unwritten extent conversion.
		 */
		if (handle) {
			ext4_put_io_end_defer(mpd.io_submit.io_end);
			ext4_journal_stop(handle);
		} else
			ext4_put_io_end(mpd.io_submit.io_end);

		if (ret == -ENOSPC && sbi->s_journal) {
			/*
			 * Commit the transaction which would
			 * free blocks released in the transaction
			 * and try again
			 */
			jbd2_journal_force_commit_nested(sbi->s_journal);
			ret = 0;
			continue;
		}
		/* Fatal error - ENOMEM, EIO... */
		if (ret)
			break;
	}
	blk_finish_plug(&plug);
	if (!ret && !cycled && wbc->nr_to_write > 0) {
		cycled = 1;
		mpd.last_page = writeback_index - 1;
		mpd.first_page = 0;
		goto retry;
	}

	/* Update index */
	if (wbc->range_cyclic || (range_whole && wbc->nr_to_write > 0))
		/*
		 * Set the writeback_index so that range_cyclic
		 * mode will write it back later
		 */
		mapping->writeback_index = mpd.first_page;

out_writepages:
	trace_ext4_writepages_result(inode, wbc, ret,
				     nr_to_write - wbc->nr_to_write);
	return ret;
}
```