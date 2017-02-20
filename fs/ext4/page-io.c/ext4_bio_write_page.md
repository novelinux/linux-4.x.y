# ext4_bio_write_page

```
int ext4_bio_write_page(struct ext4_io_submit *io,
			struct page *page,
			int len,
			struct writeback_control *wbc,
			bool keep_towrite)
{
	struct page *data_page = NULL;
	struct inode *inode = page->mapping->host;
	unsigned block_start, blocksize;
	struct buffer_head *bh, *head;
	int ret = 0;
	int nr_submitted = 0;
	int nr_to_submit = 0;

	blocksize = 1 << inode->i_blkbits;

	BUG_ON(!PageLocked(page));
	BUG_ON(PageWriteback(page));

	if (keep_towrite)
		set_page_writeback_keepwrite(page);
	else
		set_page_writeback(page);
	ClearPageError(page);

	/*
	 * Comments copied from block_write_full_page:
	 *
	 * The page straddles i_size.  It must be zeroed out on each and every
	 * writepage invocation because it may be mmapped.  "A file is mapped
	 * in multiples of the page size.  For a file that is not a multiple of
	 * the page size, the remaining memory is zeroed when mapped, and
	 * writes to that region are not written out to the file."
	 */
	if (len < PAGE_CACHE_SIZE)
		zero_user_segment(page, len, PAGE_CACHE_SIZE);
	/*
	 * In the first loop we prepare and mark buffers to submit. We have to
	 * mark all buffers in the page before submitting so that
	 * end_page_writeback() cannot be called from ext4_bio_end_io() when IO
	 * on the first buffer finishes and we are still working on submitting
	 * the second buffer.
	 */
	bh = head = page_buffers(page);
	do {
		block_start = bh_offset(bh);
		if (block_start >= len) {
			clear_buffer_dirty(bh);
			set_buffer_uptodate(bh);
			continue;
		}
		if (!buffer_dirty(bh) || buffer_delay(bh) ||
		    !buffer_mapped(bh) || buffer_unwritten(bh)) {
			/* A hole? We can safely clear the dirty bit */
			if (!buffer_mapped(bh))
				clear_buffer_dirty(bh);
			if (io->io_bio)
				ext4_io_submit(io);
			continue;
		}
		if (buffer_new(bh)) {
			clear_buffer_new(bh);
			unmap_underlying_metadata(bh->b_bdev, bh->b_blocknr);
		}
		set_buffer_async_write(bh);
		nr_to_submit++;
	} while ((bh = bh->b_this_page) != head);

	bh = head = page_buffers(page);

	if (ext4_encrypted_inode(inode) && S_ISREG(inode->i_mode) &&
	    nr_to_submit) {
		gfp_t gfp_flags = GFP_NOFS;

	retry_encrypt:

		if (!ext4_using_hardware_encryption(inode))
			data_page = ext4_encrypt(inode, page, gfp_flags);


		if (IS_ERR(data_page)) {
			ret = PTR_ERR(data_page);
			if (ret == ENOMEM && wbc->sync_mode == WB_SYNC_ALL) {
				if (io->io_bio) {
					ext4_io_submit(io);
					congestion_wait(BLK_RW_ASYNC, HZ/50);
				}
				gfp_flags |= __GFP_NOFAIL;
				goto retry_encrypt;
			}
			data_page = NULL;
			goto out;
		}
	}

	/* Now submit buffers to write */
	do {
		if (!buffer_async_write(bh))
			continue;
		ret = io_submit_add_bh(io, inode,
				       data_page ? data_page : page, bh);
		if (ret) {
			/*
			 * We only get here on ENOMEM.  Not much else
			 * we can do but mark the page as dirty, and
			 * better luck next time.
			 */
			break;
		}
		nr_submitted++;
		clear_buffer_dirty(bh);
	} while ((bh = bh->b_this_page) != head);

	/* Error stopped previous loop? Clean up buffers... */
	if (ret) {
	out:
		if (data_page)
			ext4_restore_control_page(data_page);
		printk_ratelimited(KERN_ERR "%s: ret = %d\n", __func__, ret);
		redirty_page_for_writepage(wbc, page);
		do {
			clear_buffer_async_write(bh);
			bh = bh->b_this_page;
		} while (bh != head);
	}
	unlock_page(page);
	/* Nothing submitted - we have to end page writeback */
	if (!nr_submitted)
		end_page_writeback(page);
	return ret;
}
```