# ext4_submit_bio_read

```
static void
ext4_submit_bio_read(struct bio *bio)
{
	if (trace_android_fs_dataread_start_enabled()) {
		struct page *first_page = bio->bi_io_vec[0].bv_page;

		if (first_page != NULL) {
			char *path, pathbuf[MAX_TRACE_PATHBUF_LEN];

			path = android_fstrace_get_pathname(pathbuf,
						    MAX_TRACE_PATHBUF_LEN,
						    first_page->mapping->host);
			trace_android_fs_dataread_start(
				first_page->mapping->host,
				page_offset(first_page),
				bio->bi_iter.bi_size,
				current->pid,
				path,
				current->comm);
		}
	}
	submit_bio(READ, bio);
}
```