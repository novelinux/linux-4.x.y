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