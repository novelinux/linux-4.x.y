# mpage_end_io

```
/*
 * I/O completion handler for multipage BIOs.
 *
 * The mpage code never puts partial pages into a BIO (except for end-of-file).
 * If a page does not map to a contiguous run of blocks then it simply falls
 * back to block_read_full_page().
 *
 * Why is this?  If a page's completion depends on a number of different BIOs
 * which can complete in any order (or at the same time) then determining the
 * status of that page is hard.  See end_buffer_async_read() for the details.
 * There is no point in duplicating all that complexity.
 */
static void mpage_end_io(struct bio *bio)
{
	struct bio_vec *bv;
	int i;

	if (trace_android_fs_dataread_start_enabled())
		ext4_trace_read_completion(bio);

	if (ext4_bio_encrypted(bio)) {
		struct ext4_crypto_ctx *ctx = bio->bi_private;

		if (bio->bi_error) {
			ext4_release_crypto_ctx(ctx);
		} else {
			INIT_WORK(&ctx->r.work, completion_pages);
			ctx->r.bio = bio;
			queue_work(ext4_read_workqueue, &ctx->r.work);
			return;
		}
	}
	bio_for_each_segment_all(bv, bio, i) {
		struct page *page = bv->bv_page;

		if (!bio->bi_error) {
			SetPageUptodate(page);
		} else {
			ClearPageUptodate(page);
			SetPageError(page);
		}
		unlock_page(page);
	}

	bio_put(bio);
}
```

若数据完全就绪,此时就设置page的PG_update标志,然后解锁页面。当读进程再次被调度执行时,就不会再被阻塞在lock_page_killable()函数中了。