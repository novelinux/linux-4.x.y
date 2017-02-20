# mpage_submit_page

```
static int mpage_submit_page(struct mpage_da_data *mpd, struct page *page)
{
	int len;
	loff_t size = i_size_read(mpd->inode);
	int err;

	BUG_ON(page->index != mpd->first_page);
	if (page->index == size >> PAGE_CACHE_SHIFT)
		len = size & ~PAGE_CACHE_MASK;
	else
		len = PAGE_CACHE_SIZE;
	clear_page_dirty_for_io(page);
```

## ext4_bio_write_page

```
	err = ext4_bio_write_page(&mpd->io_submit, page, len, mpd->wbc, false);
	if (!err)
		mpd->wbc->nr_to_write--;
	mpd->first_page++;

	return err;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/page-io.c/ext4_bio_write_page.md
