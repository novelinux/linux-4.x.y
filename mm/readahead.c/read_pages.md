## read_pages

```
static int read_pages(struct address_space *mapping, struct file *filp,
		struct list_head *pages, unsigned int nr_pages, gfp_t gfp)
{
	struct blk_plug plug;
	unsigned page_idx;
	int ret;

	blk_start_plug(&plug);

	if (mapping->a_ops->readpages) {
		ret = mapping->a_ops->readpages(filp, mapping, pages, nr_pages);
		/* Clean up the remaining pages */
		put_pages_list(pages);
		goto out;
	}

	for (page_idx = 0; page_idx < nr_pages; page_idx++) {
		struct page *page = lru_to_page(pages);
		list_del(&page->lru);
		if (!add_to_page_cache_lru(page, mapping, page->index, gfp))
			mapping->a_ops->readpage(filp, page);
		put_page(page);
	}
	ret = 0;

out:
	blk_finish_plug(&plug);

	return ret;
}
```

ext4文件系统的address_space_operations对象中的readpages方法实现为ext4_readpages()。若readpages方法没有定义,则readpage方法来每次读取一页。从方法名字,我们很容易看出两者的区别,readpages是一次可以读取多个页面,readpage是每次只读取一个页面。两个方法实现上差别不大,我们以ext4文件系统为例,只考虑readpages方法。

[ext4_readpages](../../fs/ext4/inode.c/ext4_readpages.md)