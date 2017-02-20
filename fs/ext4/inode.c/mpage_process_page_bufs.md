# mpage_process_page_bufs

```
/*
 * mpage_process_page_bufs - submit page buffers for IO or add them to extent
 *
 * @mpd - extent of blocks for mapping
 * @head - the first buffer in the page
 * @bh - buffer we should start processing from
 * @lblk - logical number of the block in the file corresponding to @bh
 *
 * Walk through page buffers from @bh upto @head (exclusive) and either submit
 * the page for IO if all buffers in this page were mapped and there's no
 * accumulated extent of buffers to map or add buffers in the page to the
 * extent of buffers to map. The function returns 1 if the caller can continue
 * by processing the next page, 0 if it should stop adding buffers to the
 * extent to map because we cannot extend it anymore. It can also return value
 * < 0 in case of error during IO submission.
 */
static int mpage_process_page_bufs(struct mpage_da_data *mpd,
				   struct buffer_head *head,
				   struct buffer_head *bh,
				   ext4_lblk_t lblk)
{
	struct inode *inode = mpd->inode;
	int err;
	ext4_lblk_t blocks = (i_size_read(inode) + (1 << inode->i_blkbits) - 1)
							>> inode->i_blkbits;

	do {
		BUG_ON(buffer_locked(bh));

		if (lblk >= blocks || !mpage_add_bh_to_extent(mpd, lblk, bh)) {
			/* Found extent to map? */
			if (mpd->map.m_len)
				return 0;
			/* Everything mapped so far and we hit EOF */
			break;
		}
	} while (lblk++, (bh = bh->b_this_page) != head);
```

## mpage_submit_page

```
	/* So far everything mapped? Submit the page for IO. */
	if (mpd->map.m_len == 0) {
		err = mpage_submit_page(mpd, head->b_page);
		if (err < 0)
			return err;
	}
	return lblk < blocks;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/inode.c/mpage_submit_page.md
